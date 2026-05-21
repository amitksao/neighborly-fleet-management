import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Ride, RideStatus, PaymentStatus } from '../../rides/entities/ride.entity';
import { Fleet, FleetStatus } from '../entities/fleet.entity';
import { FleetDriver, FleetDriverStatus } from '../entities/fleet-driver.entity';
import { Community } from '../../communities/entities/community.entity';
import { User } from '../../users/entities/user.entity';
import { BookFleetRideDto } from '../dto/fleet-ride.dto';
import { RedisService } from '../../common/services/redis.service';
import { NotificationService } from '../../common/services/notification.service';
import { GooglePlacesService } from '../../google-places/google-places.service';
import { FleetPayoutService } from './fleet-payout.service';
import { NotificationType, NotificationPriority } from '../../common/interfaces/notification.interface';

const MAX_ASSIGNMENT_ATTEMPTS = 3;
const ASSIGNMENT_TTL_SECONDS = 60;

@Injectable()
export class FleetRideService {
  private readonly logger = new Logger(FleetRideService.name);

  constructor(
    @InjectRepository(Ride)
    private readonly rideRepository: Repository<Ride>,
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    @InjectRepository(FleetDriver)
    private readonly fleetDriverRepository: Repository<FleetDriver>,
    @InjectRepository(Community)
    private readonly communityRepository: Repository<Community>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly redisService: RedisService,
    private readonly notificationService: NotificationService,
    private readonly googlePlacesService: GooglePlacesService,
    private readonly fleetPayoutService: FleetPayoutService,
  ) {}

  async bookFleetRide(riderId: string, dto: BookFleetRideDto): Promise<Ride> {
    const tribe = await this.communityRepository.findOne({
      where: { community_id: dto.fleet_tribe_id },
      relations: ['riders'],
    });
    if (!tribe) throw new NotFoundException('Fleet tribe not found');

    const isMember = tribe.riders?.some(r => r.id === riderId);
    if (!isMember) throw new BadRequestException('You are not a member of this fleet tribe');

    const fleet = await this.fleetRepository.findOne({
      where: { tribeId: dto.fleet_tribe_id },
    });
    if (!fleet || fleet.status !== FleetStatus.APPROVED) {
      throw new BadRequestException('This fleet tribe is not available for bookings');
    }

    // Estimate route via Google Places
    let estimatedDistance: number | null = null;
    let estimatedDuration: string | null = null;
    try {
      const routeDetails = await this.googlePlacesService.getRouteDetails({
        origin: { lat: dto.pickup_latitude, lng: dto.pickup_longitude },
        destination: { lat: dto.dropoff_latitude, lng: dto.dropoff_longitude },
      });
      // getRouteDetails returns { distance: "5.2 km", duration: "12 mins", ... }
      if (routeDetails?.distance) {
        const km = parseFloat(routeDetails.distance.replace(/[^0-9.]/g, ''));
        estimatedDistance = isNaN(km) ? null : km;
      }
      estimatedDuration = routeDetails?.duration ?? null;
    } catch (err) {
      this.logger.warn('Route estimation failed, proceeding without it', err);
    }

    const ride = this.rideRepository.create({
      rider: { id: riderId } as User,
      pickup_latitude: dto.pickup_latitude,
      pickup_longitude: dto.pickup_longitude,
      pickup_address: dto.pickup_address,
      dropoff_latitude: dto.dropoff_latitude,
      dropoff_longitude: dto.dropoff_longitude,
      dropoff_address: dto.dropoff_address,
      scheduled_at: new Date(dto.scheduled_at),
      status: RideStatus.REQUESTED,
      paymentStatus: PaymentStatus.PENDING,
      estimated_distance: estimatedDistance,
      estimated_duration: estimatedDuration,
      fare: 0, // Fare calculated on assignment based on pricing engine
      fleet_id: fleet.id,
      assignment_attempts: 0,
    });

    const savedRide = await this.rideRepository.save(ride);
    this.logger.log(`Fleet ride booked: ${savedRide.id} for fleet ${fleet.id}`);

    // Kick off smart assignment (non-blocking)
    this.assignNextDriver(savedRide.id, fleet.id, 0).catch(err =>
      this.logger.error(`Assignment failed for ride ${savedRide.id}`, err),
    );

    return savedRide;
  }

  async assignNextDriver(rideId: string, fleetId: string, attempt: number): Promise<void> {
    if (attempt >= MAX_ASSIGNMENT_ATTEMPTS) {
      this.logger.warn(`All ${MAX_ASSIGNMENT_ATTEMPTS} assignment attempts exhausted for ride ${rideId}`);
      await this.rideRepository.update(rideId, { status: RideStatus.CANCELLED, cancellation_reason: 'No drivers available' });

      // Notify the rider that no drivers are available
      const ride = await this.rideRepository.findOne({ where: { id: rideId }, relations: ['rider'] });
      if (ride?.rider?.deviceToken) {
        try {
          await this.notificationService.sendToDevice({
            deviceToken: ride.rider.deviceToken,
            title: 'No Drivers Available',
            body: 'We could not find a driver for your ride. Please try again.',
            type: NotificationType.FLEET_RIDE_ASSIGNMENT,
            priority: NotificationPriority.HIGH,
            data: { rideId, status: 'cancelled' },
          });
        } catch (err) {
          this.logger.warn(`Failed to notify rider of cancellation for ride ${rideId}`, err);
        }
      }
      return;
    }

    const ride = await this.rideRepository.findOne({ where: { id: rideId }, relations: ['rider'] });
    if (!ride || ride.status !== RideStatus.REQUESTED) return;

    const alreadyAttempted = await this.getAttemptedDriverIds(rideId);

    const activeDrivers = await this.fleetDriverRepository
      .createQueryBuilder('fd')
      .leftJoinAndSelect('fd.driver', 'driver')
      .where('fd.fleet_id = :fleetId', { fleetId })
      .andWhere('fd.status = :status', { status: FleetDriverStatus.ACTIVE })
      .andWhere('driver.id NOT IN (:...excluded)', {
        excluded: alreadyAttempted.length > 0 ? alreadyAttempted : ['__none__'],
      })
      .getMany();

    if (activeDrivers.length === 0) {
      this.logger.warn(`No available drivers for ride ${rideId} on attempt ${attempt}`);
      await this.rideRepository.update(rideId, { status: RideStatus.CANCELLED, cancellation_reason: 'No drivers available' });
      return;
    }

    // Filter out drivers who were notified within the last 60 seconds (throttle)
    const availableDrivers = await this.filterThrottledDrivers(activeDrivers);
    if (availableDrivers.length === 0) {
      this.logger.warn(`All candidate drivers are throttled for ride ${rideId} — retrying with full pool`);
      // Fall back to the full pool so the ride isn't stuck; throttle is best-effort
    }
    const candidateDrivers = availableDrivers.length > 0 ? availableDrivers : activeDrivers;

    // Pick best driver by proximity
    const bestDriver = this.selectBestDriver(candidateDrivers, ride);
    if (!bestDriver) {
      await this.rideRepository.update(rideId, { status: RideStatus.CANCELLED, cancellation_reason: 'No drivers available' });
      return;
    }

    // Track attempted drivers in Redis
    await this.redisService.set(
      `fleet:ride:${rideId}:attempted`,
      JSON.stringify([...alreadyAttempted, bestDriver.driverUserId]),
      ASSIGNMENT_TTL_SECONDS * MAX_ASSIGNMENT_ATTEMPTS,
    );

    // Set 60s assignment window key
    const windowKey = `fleet:ride:${rideId}:pending:${bestDriver.driverUserId}`;
    await this.redisService.set(windowKey, '1', ASSIGNMENT_TTL_SECONDS);

    // Update ride with assigned driver
    await this.rideRepository.update(rideId, {
      driver: { id: bestDriver.driverUserId } as User,
      status: RideStatus.ACCEPTED,
      assignment_attempts: attempt + 1,
    });

    // Notify driver and mark them as recently notified (throttle future attempts within window)
    const driver = bestDriver.driver;
    if (driver?.deviceToken) {
      await this.notificationService.sendToDevice({
        deviceToken: driver.deviceToken,
        title: 'New Fleet Ride Assignment',
        body: `You have a ride assignment. Pick up from ${ride.pickup_address}. Accept within 60 seconds.`,
        type: NotificationType.FLEET_RIDE_ASSIGNMENT,
        priority: NotificationPriority.HIGH,
        data: {
          rideId: ride.id,
          pickupAddress: ride.pickup_address,
          dropoffAddress: ride.dropoff_address,
          scheduledAt: ride.scheduled_at?.toISOString(),
          windowSeconds: ASSIGNMENT_TTL_SECONDS,
        },
      });
      // Throttle: prevent this driver from receiving another fleet assignment notification
      // within the same window to avoid notification flooding on back-to-back reassignments
      await this.redisService.set(
        `fleet:driver:${bestDriver.driverUserId}:notified`,
        '1',
        ASSIGNMENT_TTL_SECONDS,
      );
    }

    // Schedule timeout fallback via Redis expiry check (handled by ride expiration service hook)
    this.logger.log(`Ride ${rideId} assigned to driver ${bestDriver.driverUserId} (attempt ${attempt + 1})`);
  }

  async acceptRide(rideId: string, driverId: string): Promise<Ride> {
    const ride = await this.rideRepository.findOne({
      where: { id: rideId },
      relations: ['driver', 'rider'],
    });
    if (!ride) throw new NotFoundException('Ride not found');
    if ((ride.driver as User)?.id !== driverId) {
      throw new BadRequestException('This ride is not assigned to you');
    }

    const windowKey = `fleet:ride:${rideId}:pending:${driverId}`;
    const windowExists = await this.redisService.get(windowKey);
    if (!windowExists) {
      throw new BadRequestException('Assignment window has expired');
    }

    await this.redisService.del(windowKey);
    ride.status = RideStatus.ACCEPTED;
    const saved = await this.rideRepository.save(ride);

    // Notify rider
    if (ride.rider?.deviceToken) {
      await this.notificationService.sendToDevice({
        deviceToken: ride.rider.deviceToken,
        title: 'Driver On The Way!',
        body: `Your driver ${ride.driver?.name} has accepted and is on the way.`,
        type: NotificationType.FLEET_RIDE_ACCEPTED,
        priority: NotificationPriority.HIGH,
        data: { rideId: ride.id, driverId },
      });
    }

    return saved;
  }

  async declineRide(rideId: string, driverId: string): Promise<void> {
    const ride = await this.rideRepository.findOne({
      where: { id: rideId },
      relations: ['driver'],
    });
    if (!ride) throw new NotFoundException('Ride not found');

    const windowKey = `fleet:ride:${rideId}:pending:${driverId}`;
    await this.redisService.del(windowKey);

    // Re-queue assignment
    const fleetId = ride.fleet_id;
    const attempts = ride.assignment_attempts ?? 0;
    await this.rideRepository.update(rideId, { status: RideStatus.REQUESTED, driver: null });
    await this.assignNextDriver(rideId, fleetId, attempts);
  }

  async completeRide(rideId: string, driverId: string): Promise<Ride> {
    const ride = await this.rideRepository.findOne({
      where: { id: rideId },
      relations: ['driver', 'rider'],
    });
    if (!ride) throw new NotFoundException('Ride not found');
    if ((ride.driver as User)?.id !== driverId) {
      throw new BadRequestException('You are not the driver for this ride');
    }

    ride.status = RideStatus.COMPLETED;
    ride.completed_at = new Date();
    const saved = await this.rideRepository.save(ride);

    // Trigger fleet payout (best-effort)
    const fleetId = ride.fleet_id;
    if (fleetId) {
      this.fleetPayoutService.processRidePayout(rideId, fleetId).catch(err =>
        this.logger.error(`Payout failed for ride ${rideId}`, err),
      );
    }

    return saved;
  }

  async joinFleetTribe(riderId: string, tribeId: string): Promise<{ status: string; message: string }> {
    const tribe = await this.communityRepository.findOne({
      where: { community_id: tribeId },
      relations: ['riders'],
    });
    if (!tribe) throw new NotFoundException('Fleet tribe not found');

    const already = tribe.riders?.some(r => r.id === riderId);
    if (already) throw new ConflictError('Already a member of this tribe');

    const rider = await this.userRepository.findOne({ where: { id: riderId } });
    if (!rider) throw new NotFoundException('Rider not found');

    if (tribe.auto_approve_riders) {
      // Auto-approve: add immediately
      tribe.riders = [...(tribe.riders || []), rider];
      await this.communityRepository.save(tribe);
      return { status: 'approved', message: 'You have been added to the fleet tribe.' };
    }

    // Manual approval: notify the fleet manager and ask them to approve
    const fleet = await this.fleetRepository.findOne({ where: { tribeId } });
    if (fleet) {
      const manager = await this.userRepository.findOne({ where: { id: fleet.managerUserId } });
      if (manager?.deviceToken) {
        await this.notificationService.sendToDevice({
          deviceToken: manager.deviceToken,
          title: 'New Tribe Join Request',
          body: `${rider.name || rider.email} has requested to join your fleet tribe.`,
          type: NotificationType.FLEET_REGISTRATION,
          priority: NotificationPriority.NORMAL,
          data: { tribeId, riderId, fleetId: fleet.id },
        });
      }
    }

    return { status: 'pending', message: 'Your request has been sent to the fleet manager for approval.' };
  }

  async removeRiderFromTribe(managerId: string, tribeId: string, riderId: string): Promise<void> {
    const tribe = await this.communityRepository.findOne({
      where: { community_id: tribeId },
      relations: ['riders'],
    });
    if (!tribe) throw new NotFoundException('Fleet tribe not found');
    tribe.riders = tribe.riders.filter(r => r.id !== riderId);
    await this.communityRepository.save(tribe);
  }

  async listFleetRides(
    fleetId: string,
    page = 1,
    limit = 20,
    status?: string,
  ) {
    const qb = this.rideRepository
      .createQueryBuilder('ride')
      .leftJoinAndSelect('ride.rider', 'rider')
      .leftJoinAndSelect('ride.driver', 'driver')
      .where('ride.fleet_id = :fleetId', { fleetId })
      .orderBy('ride.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (status) {
      qb.andWhere('ride.status = :status', { status });
    }

    const [data, total] = await qb.getManyAndCount();
    return { data, total, page, limit };
  }

  async approveRiderJoinRequest(managerId: string, tribeId: string, riderId: string): Promise<Community> {
    const tribe = await this.communityRepository.findOne({
      where: { community_id: tribeId },
      relations: ['riders', 'driver'],
    });
    if (!tribe) throw new NotFoundException('Fleet tribe not found');

    // Verify the caller is the fleet manager for this tribe
    const fleet = await this.fleetRepository.findOne({ where: { tribeId } });
    if (!fleet || fleet.managerUserId !== managerId) {
      throw new BadRequestException('Only the fleet manager can approve tribe members');
    }

    const alreadyMember = tribe.riders?.some(r => r.id === riderId);
    if (alreadyMember) throw new BadRequestException('Rider is already a member of this tribe');

    const rider = await this.userRepository.findOne({ where: { id: riderId } });
    if (!rider) throw new NotFoundException('Rider not found');

    tribe.riders = [...(tribe.riders || []), rider];
    const saved = await this.communityRepository.save(tribe);

    // Notify rider of approval
    if (rider.deviceToken) {
      await this.notificationService.sendToDevice({
        deviceToken: rider.deviceToken,
        title: 'Tribe Access Approved!',
        body: `You have been approved to join ${fleet.company_name}'s fleet tribe.`,
        type: NotificationType.FLEET_REGISTRATION,
        priority: NotificationPriority.NORMAL,
        data: { tribeId, fleetId: fleet.id },
      });
    }

    return saved;
  }

  async getRide(rideId: string): Promise<Ride> {
    const ride = await this.rideRepository.findOne({
      where: { id: rideId },
      relations: ['rider', 'driver'],
    });
    if (!ride) throw new NotFoundException('Ride not found');
    return ride;
  }

  /**
   * Estimate fare before booking.
   * Returns: { distance_km, duration, fare_estimate }
   * Fare = fleet base_fare_per_km (stored on Fleet or a flat rate) applied to distance.
   * Fleet entity currently stores platform_fee_pct; we use a $1.50/km default for now.
   */
  async estimateFare(
    pickupLat: number,
    pickupLng: number,
    dropoffLat: number,
    dropoffLng: number,
    fleetId: string,
  ): Promise<{ distance_km: number | null; duration: string | null; fare_estimate: number | null }> {
    const fleet = await this.fleetRepository.findOne({ where: { id: fleetId } });
    if (!fleet || fleet.status !== FleetStatus.APPROVED) {
      throw new BadRequestException('Fleet not available');
    }

    let distance_km: number | null = null;
    let duration: string | null = null;
    try {
      const routeDetails = await this.googlePlacesService.getRouteDetails({
        origin: { lat: pickupLat, lng: pickupLng },
        destination: { lat: dropoffLat, lng: dropoffLng },
      });
      if (routeDetails?.distance) {
        const km = parseFloat(routeDetails.distance.replace(/[^0-9.]/g, ''));
        distance_km = isNaN(km) ? null : km;
      }
      duration = routeDetails?.duration ?? null;
    } catch (err) {
      this.logger.warn('Route estimation failed during fare estimate', err);
    }

    const RATE_PER_KM = 1.5; // USD — replace with fleet-level pricing config when available
    const fare_estimate = distance_km !== null ? Math.round(distance_km * RATE_PER_KM * 100) / 100 : null;

    return { distance_km, duration, fare_estimate };
  }

  async searchPlaces(input: string): Promise<unknown> {
    return this.googlePlacesService.searchPlaces(input);
  }

  async getPlaceDetails(placeId: string): Promise<unknown> {
    return this.googlePlacesService.getPlaceDetails(placeId);
  }

  async discoverFleetTribes(page = 1, limit = 20) {
    const [data, total] = await this.communityRepository
      .createQueryBuilder('c')
      .where("c.type = 'fleet'")
      .andWhere('c.is_public = true')
      .leftJoinAndSelect('c.driver', 'manager')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data, total, page, limit };
  }

  private selectBestDriver(drivers: FleetDriver[], ride: Ride): FleetDriver | null {
    const withLocation = drivers.filter(d => d.driver?.lastLocation);
    if (withLocation.length === 0) return drivers[0] ?? null;

    return withLocation.reduce((best, fd) => {
      const dist = haversine(
        fd.driver.lastLocation.latitude,
        fd.driver.lastLocation.longitude,
        ride.pickup_latitude as unknown as number,
        ride.pickup_longitude as unknown as number,
      );
      const bestDist = haversine(
        best.driver.lastLocation.latitude,
        best.driver.lastLocation.longitude,
        ride.pickup_latitude as unknown as number,
        ride.pickup_longitude as unknown as number,
      );
      return dist < bestDist ? fd : best;
    });
  }

  private async filterThrottledDrivers(drivers: FleetDriver[]): Promise<FleetDriver[]> {
    const results = await Promise.all(
      drivers.map(async (fd) => {
        const throttled = await this.redisService.get(`fleet:driver:${fd.driverUserId}:notified`);
        return throttled ? null : fd;
      }),
    );
    return results.filter((fd): fd is FleetDriver => fd !== null);
  }

  private async getAttemptedDriverIds(rideId: string): Promise<string[]> {
    try {
      const raw = await this.redisService.get(`fleet:ride:${rideId}:attempted`);
      return raw ? JSON.parse(raw) : [];
    } catch {
      return [];
    }
  }
}

class ConflictError extends BadRequestException {}

function haversine(lat1: number, lon1: number, lat2: number, lon2: number): number {
  const R = 6371;
  const dLat = ((lat2 - lat1) * Math.PI) / 180;
  const dLon = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dLat / 2) ** 2 +
    Math.cos((lat1 * Math.PI) / 180) *
      Math.cos((lat2 * Math.PI) / 180) *
      Math.sin(dLon / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

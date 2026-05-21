import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Ride, RideStatus, PaymentStatus } from '../../rides/entities/ride.entity';
import { Fleet } from '../entities/fleet.entity';
import { FleetDriver, FleetDriverStatus } from '../entities/fleet-driver.entity';

export interface FleetAnalytics {
  totalRides: number;
  completedRides: number;
  cancelledRides: number;
  totalEarningsGross: number;
  totalPlatformFees: number;
  totalNetPayouts: number;
  activeDrivers: number;
  inactiveDrivers: number;
  averageRidesPerDriver: number;
  periodDays: number;
}

@Injectable()
export class FleetAnalyticsService {
  constructor(
    @InjectRepository(Ride)
    private readonly rideRepository: Repository<Ride>,
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    @InjectRepository(FleetDriver)
    private readonly fleetDriverRepository: Repository<FleetDriver>,
  ) {}

  async getFleetAnalytics(fleetId: string, days: number = 30): Promise<FleetAnalytics> {
    const fleet = await this.fleetRepository.findOne({ where: { id: fleetId } });
    if (!fleet) throw new NotFoundException('Fleet not found');

    const since = new Date();
    since.setDate(since.getDate() - days);

    const rides = await this.rideRepository
      .createQueryBuilder('ride')
      .where('ride.fleet_id = :fleetId', { fleetId })
      .andWhere('ride.created_at >= :since', { since })
      .getMany();

    const completedRides = rides.filter(r => r.status === RideStatus.COMPLETED);
    const cancelledRides = rides.filter(r => r.status === RideStatus.CANCELLED);

    const totalEarningsGross = completedRides.reduce((sum, r) => sum + Number(r.fare), 0);
    const totalPlatformFees = completedRides.reduce(
      (sum, r) => sum + Number(r.platform_fee_amount ?? 0),
      0,
    );
    const totalNetPayouts = totalEarningsGross - totalPlatformFees;

    const [activeDrivers, inactiveDrivers] = await Promise.all([
      this.fleetDriverRepository.count({ where: { fleetId, status: FleetDriverStatus.ACTIVE } }),
      this.fleetDriverRepository.count({ where: { fleetId, status: FleetDriverStatus.INACTIVE } }),
    ]);

    const averageRidesPerDriver = activeDrivers > 0 ? completedRides.length / activeDrivers : 0;

    return {
      totalRides: rides.length,
      completedRides: completedRides.length,
      cancelledRides: cancelledRides.length,
      totalEarningsGross: Math.round(totalEarningsGross * 100) / 100,
      totalPlatformFees: Math.round(totalPlatformFees * 100) / 100,
      totalNetPayouts: Math.round(totalNetPayouts * 100) / 100,
      activeDrivers,
      inactiveDrivers,
      averageRidesPerDriver: Math.round(averageRidesPerDriver * 10) / 10,
      periodDays: days,
    };
  }

  async getDriverPerformance(fleetId: string, driverUserId: string, days = 30) {
    const since = new Date();
    since.setDate(since.getDate() - days);

    const rides = await this.rideRepository
      .createQueryBuilder('ride')
      .where('ride.fleet_id = :fleetId', { fleetId })
      .andWhere('ride.driver_id = :driverUserId', { driverUserId })
      .andWhere('ride.created_at >= :since', { since })
      .getMany();

    const completed = rides.filter(r => r.status === RideStatus.COMPLETED);
    const totalEarnings = completed.reduce((s, r) => s + Number(r.fare), 0);

    return {
      totalRides: rides.length,
      completedRides: completed.length,
      completionRate: rides.length > 0 ? (completed.length / rides.length) * 100 : 0,
      totalEarnings: Math.round(totalEarnings * 100) / 100,
      periodDays: days,
    };
  }

  async getPlatformFleetSummary() {
    const fleets = await this.fleetRepository.find({ select: ['id', 'company_name', 'status', 'platform_fee_pct', 'created_at'] });

    const results = await Promise.all(
      fleets.map(async fleet => {
        const analytics = await this.getFleetAnalytics(fleet.id, 30);
        return { fleet, analytics };
      }),
    );

    return results;
  }
}

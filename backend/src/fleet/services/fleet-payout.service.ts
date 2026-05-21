import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Ride, PaymentStatus } from '../../rides/entities/ride.entity';
import { Fleet } from '../entities/fleet.entity';
import { EmailService } from '../../common/services/email.service';
import { NotificationService } from '../../common/services/notification.service';
import { NotificationType, NotificationPriority } from '../../common/interfaces/notification.interface';
import { User } from '../../users/entities/user.entity';
import Stripe from 'stripe';

@Injectable()
export class FleetPayoutService {
  private readonly logger = new Logger(FleetPayoutService.name);
  private stripe: Stripe;

  constructor(
    @InjectRepository(Ride)
    private readonly rideRepository: Repository<Ride>,
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly emailService: EmailService,
    private readonly notificationService: NotificationService,
  ) {
    this.stripe = new Stripe(process.env.STRIPE_SECRET_KEY!, { apiVersion: '2024-06-20' as any });
  }

  async processRidePayout(rideId: string, fleetId: string): Promise<void> {
    const ride = await this.rideRepository.findOne({
      where: { id: rideId },
      relations: ['rider'],
    });
    if (!ride) throw new NotFoundException('Ride not found');

    const fleet = await this.fleetRepository.findOne({
      where: { id: fleetId },
      relations: ['manager'],
    });
    if (!fleet?.stripe_account_id) {
      this.logger.warn(`Fleet ${fleetId} has no Stripe account — skipping payout`);
      return;
    }

    const fareInCents = Math.round(Number(ride.fare) * 100);
    const platformFeeInCents = Math.round(fareInCents * (Number(fleet.platform_fee_pct) / 100));
    const transferAmountInCents = fareInCents - platformFeeInCents;

    let transferId: string | null = null;
    try {
      const transfer = await this.stripe.transfers.create({
        amount: transferAmountInCents,
        currency: 'usd',
        destination: fleet.stripe_account_id,
        transfer_group: `ride_${rideId}`,
        metadata: {
          ride_id: rideId,
          fleet_id: fleetId,
          platform_fee_cents: platformFeeInCents,
        },
      });
      transferId = transfer.id;
      this.logger.log(`Stripe transfer ${transferId} created for ride ${rideId}`);
    } catch (err) {
      this.logger.error(`Stripe transfer failed for ride ${rideId}`, err);
      throw err;
    }

    // Persist transfer metadata on ride
    await this.rideRepository.update(rideId, {
      paymentStatus: PaymentStatus.PAID,
      fleet_payout_transfer_id: transferId,
      platform_fee_amount: platformFeeInCents / 100,
    });

    // Send receipt to rider
    if (ride.rider?.email) {
      await this.emailService.sendEmail(
        ride.rider.email,
        'Your Neighborly Fleet Ride Receipt',
        `
          <h2>Ride Receipt</h2>
          <p><strong>Fleet:</strong> ${fleet.company_name}</p>
          <p><strong>Pickup:</strong> ${ride.pickup_address}</p>
          <p><strong>Dropoff:</strong> ${ride.dropoff_address}</p>
          <p><strong>Fare:</strong> $${Number(ride.fare).toFixed(2)}</p>
          <p><strong>Date:</strong> ${ride.completed_at?.toLocaleDateString()}</p>
        `,
      );
    }

    // Notify fleet manager of payout
    if (fleet.manager?.deviceToken) {
      await this.notificationService.sendToDevice({
        deviceToken: fleet.manager.deviceToken,
        title: 'Ride Payout Processed',
        body: `$${(transferAmountInCents / 100).toFixed(2)} transferred to your fleet account for ride ${rideId}.`,
        type: NotificationType.FLEET_PAYOUT,
        priority: NotificationPriority.NORMAL,
        data: { rideId, fleetId, transferId, amount: transferAmountInCents / 100 },
      });
    }
  }

  async getPayoutHistory(fleetId: string, page = 1, limit = 20) {
    const [data, total] = await this.rideRepository
      .createQueryBuilder('ride')
      .where('ride.fleet_id = :fleetId', { fleetId })
      .andWhere('ride.paymentStatus = :status', { status: PaymentStatus.PAID })
      .andWhere('ride.fleet_payout_transfer_id IS NOT NULL')
      // fleet_payout_transfer_id and platform_fee_amount are now typed on the Ride entity
      .select([
        'ride.id',
        'ride.fare',
        'ride.platform_fee_amount',
        'ride.fleet_payout_transfer_id',
        'ride.completed_at',
        'ride.pickup_address',
        'ride.dropoff_address',
      ])
      .orderBy('ride.completed_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit)
      .getManyAndCount();

    return { data, total, page, limit };
  }
}

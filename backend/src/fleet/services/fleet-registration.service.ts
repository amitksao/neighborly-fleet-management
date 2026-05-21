import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, DataSource } from 'typeorm';
import { Fleet, FleetStatus } from '../entities/fleet.entity';
import { CreateFleetDto } from '../dto/create-fleet.dto';
import { UpdateFleetDto, SetFleetFeeDto } from '../dto/update-fleet.dto';
import { Community } from '../../communities/entities/community.entity';
import { User } from '../../users/entities/user.entity';
import { NotificationService } from '../../common/services/notification.service';
import { EmailService } from '../../common/services/email.service';
import { StripeConnectService } from '../../stripe/services/stripe-connect.service';
import { NotificationType, NotificationPriority } from '../../common/interfaces/notification.interface';
import { UserRole } from '../../users/entities/user.entity';
import { CommunityType } from '../../communities/entities/community.entity';
import { StripeAccountType } from '../../config/stripe';

@Injectable()
export class FleetRegistrationService {
  private readonly logger = new Logger(FleetRegistrationService.name);

  constructor(
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    @InjectRepository(Community)
    private readonly communityRepository: Repository<Community>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly notificationService: NotificationService,
    private readonly emailService: EmailService,
    private readonly stripeConnectService: StripeConnectService,
    private readonly dataSource: DataSource,
  ) {}

  async registerFleet(managerId: string, dto: CreateFleetDto): Promise<Fleet> {
    const existingFleet = await this.fleetRepository.findOne({
      where: { managerUserId: managerId },
    });
    if (existingFleet) {
      throw new ConflictException('You have already registered a fleet');
    }

    const emailTaken = await this.fleetRepository.findOne({
      where: { company_email: dto.company_email },
    });
    if (emailTaken) {
      throw new ConflictException('A fleet with this email already exists');
    }

    const fleet = this.fleetRepository.create({
      ...dto,
      managerUserId: managerId,
      status: FleetStatus.PENDING_APPROVAL,
    });

    const saved = await this.fleetRepository.save(fleet);
    this.logger.log(`Fleet registered: ${saved.id} by manager: ${managerId}`);

    // Notify platform admins via push (best-effort)
    try {
      const admins = await this.userRepository.find({ where: { role: UserRole.ADMIN } });
      for (const admin of admins) {
        if (admin.deviceToken) {
          await this.notificationService.sendToDevice({
            deviceToken: admin.deviceToken,
            title: 'New Fleet Registration',
            body: `${dto.company_name} has submitted a fleet application for review.`,
            type: NotificationType.FLEET_REGISTRATION,
            priority: NotificationPriority.HIGH,
            data: { fleetId: saved.id },
          });
        }
      }
    } catch (err) {
      this.logger.warn('Failed to notify admins of new fleet registration', err);
    }

    return saved;
  }

  async initiateStripeOnboarding(fleetId: string, managerId: string): Promise<string> {
    const fleet = await this.findByIdOrFail(fleetId);
    const manager = await this.userRepository.findOne({ where: { id: managerId } });

    if (!manager) throw new NotFoundException('Manager user not found');

    const { account, onboardingUrl } = await this.stripeConnectService.createConnectAccount(managerId, {
      accountType: StripeAccountType.EXPRESS,
      businessName: fleet.company_name,
      email: fleet.company_email,
      phone: fleet.company_phone,
      country: 'US',
    });

    // Persist the Stripe account ID immediately so payout transfers can reference it
    fleet.stripe_account_id = account.stripeAccountId;
    await this.fleetRepository.save(fleet);

    this.logger.log(`Stripe onboarding initiated for fleet ${fleetId}, account ${account.stripeAccountId}`);
    return onboardingUrl;
  }

  async handleStripeAccountUpdated(stripeAccountId: string, payoutsEnabled: boolean): Promise<void> {
    const fleet = await this.fleetRepository.findOne({ where: { stripe_account_id: stripeAccountId } });
    if (!fleet) {
      this.logger.warn(`Stripe webhook: no fleet found for account ${stripeAccountId}`);
      return;
    }

    if (payoutsEnabled) {
      this.logger.log(`Fleet ${fleet.id} Stripe account ${stripeAccountId} payouts enabled`);
      // Notify the fleet manager that their Stripe account is fully set up
      const manager = await this.userRepository.findOne({ where: { id: fleet.managerUserId } });
      if (manager?.deviceToken) {
        try {
          await this.notificationService.sendToDevice({
            deviceToken: manager.deviceToken,
            title: 'Payments Ready',
            body: 'Your Stripe account is verified. You can now receive payouts.',
            type: NotificationType.FLEET_APPROVED,
            priority: NotificationPriority.HIGH,
            data: { fleetId: fleet.id },
          });
        } catch (err) {
          this.logger.warn('Failed to notify manager of Stripe activation', err);
        }
      }
    }
  }

  async approveFleet(fleetId: string): Promise<Fleet> {
    const fleet = await this.findByIdOrFail(fleetId);

    if (fleet.status !== FleetStatus.PENDING_APPROVAL) {
      throw new BadRequestException(`Fleet status is '${fleet.status}', cannot approve`);
    }

    const queryRunner = this.dataSource.createQueryRunner();
    await queryRunner.connect();
    await queryRunner.startTransaction();

    try {
      // Update fleet status
      fleet.status = FleetStatus.APPROVED;
      fleet.approved_at = new Date();
      await queryRunner.manager.save(Fleet, fleet);

      // Auto-create the Fleet Tribe (Community)
      const tribe = queryRunner.manager.create(Community, {
        name: `${fleet.company_name} Fleet`,
        description: `Official fleet tribe for ${fleet.company_name}`,
        driver: fleet.manager,
        type: CommunityType.FLEET,
        is_public: true,
        auto_approve_riders: false,
      });
      const savedTribe = await queryRunner.manager.save(Community, tribe);

      // Link tribe back to fleet
      fleet.tribeId = savedTribe.community_id;
      await queryRunner.manager.save(Fleet, fleet);

      await queryRunner.commitTransaction();

      // Notify fleet manager
      const manager = await this.userRepository.findOne({ where: { id: fleet.managerUserId } });
      if (manager?.deviceToken) {
        await this.notificationService.sendToDevice({
          deviceToken: manager.deviceToken,
          title: 'Fleet Approved!',
          body: `${fleet.company_name} has been approved. You can now invite drivers.`,
          type: NotificationType.FLEET_APPROVED,
          priority: NotificationPriority.HIGH,
          data: { fleetId: fleet.id, tribeId: savedTribe.community_id },
        });
      }
      if (manager?.email) {
        await this.emailService.sendEmail({
          to: manager.email,
          subject: `Your fleet "${fleet.company_name}" has been approved`,
          html: `<p>Congratulations! Your fleet has been approved. Log in to start inviting drivers.</p>`,
        });
      }

      this.logger.log(`Fleet approved: ${fleetId}`);
      return fleet;
    } catch (err) {
      await queryRunner.rollbackTransaction();
      throw err;
    } finally {
      await queryRunner.release();
    }
  }

  async rejectFleet(fleetId: string, reason: string): Promise<Fleet> {
    const fleet = await this.findByIdOrFail(fleetId);

    if (fleet.status !== FleetStatus.PENDING_APPROVAL) {
      throw new BadRequestException(`Fleet status is '${fleet.status}', cannot reject`);
    }

    fleet.status = FleetStatus.REJECTED;
    fleet.rejection_reason = reason;
    const saved = await this.fleetRepository.save(fleet);

    const manager = await this.userRepository.findOne({ where: { id: fleet.managerUserId } });
    if (manager?.email) {
      await this.emailService.sendEmail({
        to: manager.email,
        subject: `Fleet application update for "${fleet.company_name}"`,
        html: `<p>Your fleet application was not approved. Reason: ${reason}</p>`,
      });
    }

    return saved;
  }

  async suspendFleet(fleetId: string): Promise<Fleet> {
    const fleet = await this.findByIdOrFail(fleetId);
    fleet.status = FleetStatus.SUSPENDED;
    return this.fleetRepository.save(fleet);
  }

  async setFleetFee(fleetId: string, dto: SetFleetFeeDto): Promise<Fleet> {
    const fleet = await this.findByIdOrFail(fleetId);
    fleet.platform_fee_pct = dto.platform_fee_pct;
    return this.fleetRepository.save(fleet);
  }

  async updateFleet(fleetId: string, dto: UpdateFleetDto): Promise<Fleet> {
    const fleet = await this.findByIdOrFail(fleetId);
    Object.assign(fleet, dto);
    return this.fleetRepository.save(fleet);
  }

  async findById(fleetId: string): Promise<Fleet> {
    return this.findByIdOrFail(fleetId);
  }

  async findAll(filters: { status?: FleetStatus; page?: number; limit?: number }) {
    const { status, page = 1, limit = 20 } = filters;
    const qb = this.fleetRepository
      .createQueryBuilder('fleet')
      .leftJoinAndSelect('fleet.manager', 'manager')
      .orderBy('fleet.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (status) qb.andWhere('fleet.status = :status', { status });

    const [data, total] = await qb.getManyAndCount();
    return { data, total, page, limit };
  }

  private async findByIdOrFail(fleetId: string): Promise<Fleet> {
    const fleet = await this.fleetRepository.findOne({
      where: { id: fleetId },
      relations: ['manager', 'tribe'],
    });
    if (!fleet) throw new NotFoundException('Fleet not found');
    return fleet;
  }
}

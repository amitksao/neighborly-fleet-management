import {
  Injectable,
  Logger,
  NotFoundException,
  BadRequestException,
  ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { JwtService } from '@nestjs/jwt';
import { FleetDriver, FleetDriverStatus } from '../entities/fleet-driver.entity';
import { FleetInvite, FleetInviteStatus } from '../entities/fleet-invite.entity';
import { Fleet, FleetStatus } from '../entities/fleet.entity';
import { InviteDriverDto } from '../dto/invite-driver.dto';
import { User } from '../../users/entities/user.entity';
import { Community } from '../../communities/entities/community.entity';
import { EmailService } from '../../common/services/email.service';
import { NotificationService } from '../../common/services/notification.service';
import { NotificationType, NotificationPriority } from '../../common/interfaces/notification.interface';

const INVITE_TTL_DAYS = 7;

@Injectable()
export class FleetDriverService {
  private readonly logger = new Logger(FleetDriverService.name);

  constructor(
    @InjectRepository(FleetDriver)
    private readonly fleetDriverRepository: Repository<FleetDriver>,
    @InjectRepository(FleetInvite)
    private readonly fleetInviteRepository: Repository<FleetInvite>,
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    @InjectRepository(Community)
    private readonly communityRepository: Repository<Community>,
    private readonly emailService: EmailService,
    private readonly notificationService: NotificationService,
    private readonly jwtService: JwtService,
  ) {}

  async inviteDriver(fleetId: string, dto: InviteDriverDto): Promise<FleetInvite> {
    const fleet = await this.getApprovedFleet(fleetId);

    // Prevent duplicate pending invite
    const existingInvite = await this.fleetInviteRepository.findOne({
      where: { fleetId, invitedEmail: dto.email, status: FleetInviteStatus.PENDING },
    });
    if (existingInvite) {
      throw new ConflictException('A pending invite already exists for this email');
    }

    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + INVITE_TTL_DAYS);

    const token = this.jwtService.sign(
      { fleetId, email: dto.email, type: 'fleet_driver_invite' },
      { expiresIn: `${INVITE_TTL_DAYS}d` },
    );

    const invite = this.fleetInviteRepository.create({
      fleetId,
      invitedEmail: dto.email,
      inviteToken: token,
      expiresAt,
      status: FleetInviteStatus.PENDING,
    });
    const savedInvite = await this.fleetInviteRepository.save(invite);

    // Also create a FleetDriver record in INVITED state
    const fleetDriver = this.fleetDriverRepository.create({
      fleetId,
      inviteEmail: dto.email,
      inviteToken: token,
      inviteExpiresAt: expiresAt,
      status: FleetDriverStatus.INVITED,
    });
    await this.fleetDriverRepository.save(fleetDriver);

    // Send invite email
    const inviteUrl = `${process.env.APP_BASE_URL}/fleet/invite/${token}`;
    await this.emailService.sendEmail({
      to: dto.email,
      subject: `You've been invited to join ${fleet.company_name} on Neighborly`,
      html: `
        <p>Hi,</p>
        <p>${fleet.company_name} has invited you to join their fleet on Neighborly as a driver.</p>
        ${dto.message ? `<p><em>"${dto.message}"</em></p>` : ''}
        <p><a href="${inviteUrl}">Accept Invitation</a></p>
        <p>This link expires in ${INVITE_TTL_DAYS} days.</p>
      `,
    });

    this.logger.log(`Driver invite sent to ${dto.email} for fleet ${fleetId}`);
    return savedInvite;
  }

  async validateInviteToken(token: string): Promise<{ fleet: Fleet; email: string }> {
    try {
      const payload = this.jwtService.verify(token) as { fleetId: string; email: string };
      const fleet = await this.fleetRepository.findOne({ where: { id: payload.fleetId } });
      if (!fleet) throw new NotFoundException('Fleet not found');

      const invite = await this.fleetInviteRepository.findOne({
        where: { inviteToken: token, status: FleetInviteStatus.PENDING },
      });
      if (!invite || invite.expiresAt < new Date()) {
        throw new BadRequestException('Invite link is invalid or has expired');
      }

      return { fleet, email: payload.email };
    } catch {
      throw new BadRequestException('Invalid or expired invite token');
    }
  }

  async acceptInvite(token: string, userId: string): Promise<FleetDriver> {
    const { fleet, email } = await this.validateInviteToken(token);

    const user = await this.userRepository.findOne({ where: { id: userId } });
    if (!user) throw new NotFoundException('User not found');

    // Mark invite accepted
    await this.fleetInviteRepository.update(
      { inviteToken: token },
      { status: FleetInviteStatus.ACCEPTED, acceptedAt: new Date() },
    );

    // Link driver to fleet record and trigger BGC
    const fleetDriver = await this.fleetDriverRepository.findOne({
      where: { fleetId: fleet.id, inviteEmail: email },
    });
    if (!fleetDriver) throw new NotFoundException('Fleet driver record not found');

    fleetDriver.driverUserId = userId;
    fleetDriver.status = FleetDriverStatus.BGC_PENDING;
    fleetDriver.bgcRequestId = await this.triggerBackgroundCheck(user, fleet);

    const saved = await this.fleetDriverRepository.save(fleetDriver);

    // Notify fleet manager
    const manager = await this.userRepository.findOne({ where: { id: fleet.managerUserId } });
    if (manager?.deviceToken) {
      await this.notificationService.sendToDevice({
        deviceToken: manager.deviceToken,
        title: 'Driver Accepted Invite',
        body: `${user.name || user.email} accepted your fleet invite and is undergoing a background check.`,
        type: NotificationType.FLEET_DRIVER_BGC,
        priority: NotificationPriority.NORMAL,
        data: { fleetId: fleet.id, driverUserId: userId },
      });
    }

    return saved;
  }

  async completeBackgroundCheck(fleetDriverId: string, passed: boolean, reason?: string): Promise<FleetDriver> {
    const fleetDriver = await this.fleetDriverRepository.findOne({
      where: { id: fleetDriverId },
      relations: ['fleet', 'driver'],
    });
    if (!fleetDriver) throw new NotFoundException('Fleet driver not found');

    if (passed) {
      fleetDriver.status = FleetDriverStatus.ACTIVE;
      fleetDriver.activatedAt = new Date();
      await this.fleetDriverRepository.save(fleetDriver);

      // Add driver to fleet tribe community
      if (fleetDriver.fleet.tribeId && fleetDriver.driver) {
        const tribe = await this.communityRepository.findOne({
          where: { community_id: fleetDriver.fleet.tribeId },
          relations: ['riders'],
        });
        if (tribe) {
          // Drivers are not riders; mark them as associated via owned_community or a separate relation
          // For now, use the riders ManyToMany as the tribe membership list
          tribe.riders = [...(tribe.riders || []), fleetDriver.driver];
          await this.communityRepository.save(tribe);
        }
      }

      // Notify driver
      if (fleetDriver.driver?.deviceToken) {
        await this.notificationService.sendToDevice({
          deviceToken: fleetDriver.driver.deviceToken,
          title: 'Background Check Passed!',
          body: `You are now an active driver for ${fleetDriver.fleet.company_name}.`,
          type: NotificationType.FLEET_BGC_PASSED,
          priority: NotificationPriority.HIGH,
          data: { fleetId: fleetDriver.fleetId },
        });
      }
    } else {
      fleetDriver.status = FleetDriverStatus.REJECTED;
      fleetDriver.rejection_reason = reason ?? 'Background check failed';
      await this.fleetDriverRepository.save(fleetDriver);

      // Notify fleet manager
      const manager = await this.userRepository.findOne({ where: { id: fleetDriver.fleet.managerUserId } });
      if (manager?.deviceToken) {
        await this.notificationService.sendToDevice({
          deviceToken: manager.deviceToken,
          title: 'Driver Background Check Failed',
          body: `A driver's background check did not pass. Reason: ${fleetDriver.rejection_reason}`,
          type: NotificationType.FLEET_BGC_FAILED,
          priority: NotificationPriority.NORMAL,
          data: { fleetId: fleetDriver.fleetId },
        });
      }
    }

    return fleetDriver;
  }

  async activateDriver(fleetId: string, driverUserId: string): Promise<FleetDriver> {
    const fd = await this.findFleetDriverOrFail(fleetId, driverUserId);
    if (fd.status === FleetDriverStatus.ACTIVE) return fd;
    fd.status = FleetDriverStatus.ACTIVE;
    fd.activatedAt = new Date();
    fd.deactivatedAt = null;
    return this.fleetDriverRepository.save(fd);
  }

  async deactivateDriver(fleetId: string, driverUserId: string): Promise<FleetDriver> {
    const fd = await this.findFleetDriverOrFail(fleetId, driverUserId);
    fd.status = FleetDriverStatus.INACTIVE;
    fd.deactivatedAt = new Date();
    return this.fleetDriverRepository.save(fd);
  }

  async getFleetDrivers(fleetId: string, status?: FleetDriverStatus, page = 1, limit = 20) {
    const qb = this.fleetDriverRepository
      .createQueryBuilder('fd')
      .leftJoinAndSelect('fd.driver', 'driver')
      .where('fd.fleet_id = :fleetId', { fleetId })
      .orderBy('fd.created_at', 'DESC')
      .skip((page - 1) * limit)
      .take(limit);

    if (status) qb.andWhere('fd.status = :status', { status });

    const [data, total] = await qb.getManyAndCount();
    return { data, total, page, limit };
  }

  private async getApprovedFleet(fleetId: string): Promise<Fleet> {
    const fleet = await this.fleetRepository.findOne({ where: { id: fleetId } });
    if (!fleet) throw new NotFoundException('Fleet not found');
    if (fleet.status !== FleetStatus.APPROVED) {
      throw new BadRequestException('Fleet must be approved before inviting drivers');
    }
    return fleet;
  }

  private async findFleetDriverOrFail(fleetId: string, driverUserId: string): Promise<FleetDriver> {
    const fd = await this.fleetDriverRepository.findOne({
      where: { fleetId, driverUserId },
    });
    if (!fd) throw new NotFoundException('Driver not found in this fleet');
    return fd;
  }

  private async triggerBackgroundCheck(user: User, fleet: Fleet): Promise<string> {
    // Hook into existing BGC vendor (stubbed — replace with real vendor call)
    this.logger.log(`Triggering BGC for user ${user.id} in fleet ${fleet.id}`);
    return `bgc-${user.id}-${Date.now()}`;
  }
}

import {
  Injectable,
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Fleet, FleetStatus } from '../entities/fleet.entity';

/**
 * Guard that ensures the authenticated user is the manager of the fleet
 * referenced by the :fleetId route parameter.
 *
 * Apply after AuthGuard:
 *   @UseGuards(AuthGuard, FleetManagerGuard)
 */
@Injectable()
export class FleetManagerGuard implements CanActivate {
  constructor(
    @InjectRepository(Fleet)
    private readonly fleetRepository: Repository<Fleet>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const user = request.user;
    const fleetId = request.params.fleetId ?? request.params.id;

    if (!fleetId) {
      throw new ForbiddenException('Fleet ID is required');
    }

    const fleet = await this.fleetRepository.findOne({
      where: { id: fleetId },
      select: ['id', 'managerUserId', 'status'],
    });

    if (!fleet) {
      throw new NotFoundException('Fleet not found');
    }

    // Platform admins can always pass
    if (user.role === 'admin') {
      request.fleet = fleet;
      return true;
    }

    if (fleet.managerUserId !== user.id) {
      throw new ForbiddenException('You are not the manager of this fleet');
    }

    if (fleet.status === FleetStatus.SUSPENDED) {
      throw new ForbiddenException('This fleet is currently suspended');
    }

    request.fleet = fleet;
    return true;
  }
}

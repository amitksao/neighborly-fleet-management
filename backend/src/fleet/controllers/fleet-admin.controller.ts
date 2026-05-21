import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  Query,
  UseGuards,
} from '@nestjs/common';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/role.guard';
import { Roles } from '../../common/decorators/roles.decorator';
import { UserRole } from '../../common/enum/roles.enum';
import { FleetRegistrationService } from '../services/fleet-registration.service';
import { FleetAnalyticsService } from '../services/fleet-analytics.service';
import { FleetPayoutService } from '../services/fleet-payout.service';
import { SetFleetFeeDto } from '../dto/update-fleet.dto';
import { FleetQueryDto } from '../dto/fleet-query.dto';

@Controller('admin/fleet')
@UseGuards(AuthGuard, RolesGuard)
@Roles(UserRole.ADMIN)
export class FleetAdminController {
  constructor(
    private readonly fleetRegistrationService: FleetRegistrationService,
    private readonly fleetAnalyticsService: FleetAnalyticsService,
    private readonly fleetPayoutService: FleetPayoutService,
  ) {}

  /** List all fleets with optional filters */
  @Get()
  findAll(@Query() query: FleetQueryDto) {
    return this.fleetRegistrationService.findAll({
      status: query.status,
      page: query.page,
      limit: query.limit,
    });
  }

  /** Approve a fleet application */
  @Post(':fleetId/approve')
  approve(@Param('fleetId') fleetId: string) {
    return this.fleetRegistrationService.approveFleet(fleetId);
  }

  /** Reject a fleet application */
  @Post(':fleetId/reject')
  reject(@Param('fleetId') fleetId: string, @Body('reason') reason: string) {
    return this.fleetRegistrationService.rejectFleet(fleetId, reason);
  }

  /** Suspend an approved fleet */
  @Post(':fleetId/suspend')
  suspend(@Param('fleetId') fleetId: string) {
    return this.fleetRegistrationService.suspendFleet(fleetId);
  }

  /** Set platform fee percentage for a fleet */
  @Patch(':fleetId/fee')
  setFee(@Param('fleetId') fleetId: string, @Body() dto: SetFleetFeeDto) {
    return this.fleetRegistrationService.setFleetFee(fleetId, dto);
  }

  /** Trigger a manual payout for a fleet */
  @Post(':fleetId/payouts/trigger')
  triggerPayout(@Param('fleetId') fleetId: string, @Body('rideId') rideId: string) {
    return this.fleetPayoutService.processRidePayout(rideId, fleetId);
  }

  /** Platform-wide fleet analytics summary */
  @Get('analytics/summary')
  platformSummary() {
    return this.fleetAnalyticsService.getPlatformFleetSummary();
  }
}

import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  Query,
  Req,
  UseGuards,
  Headers,
  UnauthorizedException,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/role.guard';
import { FleetManagerGuard } from '../guards/fleet-manager.guard';
import { FleetDriverService } from '../services/fleet-driver.service';
import { InviteDriverDto } from '../dto/invite-driver.dto';
import { FleetDriverQueryDto } from '../dto/fleet-query.dto';
import { Public } from '../../common/decorators/public.decorator';

@Controller('fleet')
@UseGuards(AuthGuard, RolesGuard)
export class FleetDriverController {
  constructor(private readonly fleetDriverService: FleetDriverService) {}

  /** Fleet Manager: invite a driver by email */
  @Post(':fleetId/drivers/invite')
  @UseGuards(FleetManagerGuard)
  invite(@Param('fleetId') fleetId: string, @Body() dto: InviteDriverDto) {
    return this.fleetDriverService.inviteDriver(fleetId, dto);
  }

  /** Fleet Manager: list all drivers in the fleet */
  @Get(':fleetId/drivers')
  @UseGuards(FleetManagerGuard)
  listDrivers(@Param('fleetId') fleetId: string, @Query() query: FleetDriverQueryDto) {
    return this.fleetDriverService.getFleetDrivers(fleetId, query.status, query.page, query.limit);
  }

  /** Fleet Manager: activate a driver */
  @Patch(':fleetId/drivers/:driverUserId/activate')
  @UseGuards(FleetManagerGuard)
  activate(@Param('fleetId') fleetId: string, @Param('driverUserId') driverUserId: string) {
    return this.fleetDriverService.activateDriver(fleetId, driverUserId);
  }

  /** Fleet Manager: deactivate a driver */
  @Patch(':fleetId/drivers/:driverUserId/deactivate')
  @UseGuards(FleetManagerGuard)
  deactivate(@Param('fleetId') fleetId: string, @Param('driverUserId') driverUserId: string) {
    return this.fleetDriverService.deactivateDriver(fleetId, driverUserId);
  }

  /** Public: validate an invite token (used by deep-link landing) */
  @Public()
  @Get('invite/:token')
  validateInvite(@Param('token') token: string) {
    return this.fleetDriverService.validateInviteToken(token);
  }

  /** Authenticated driver: accept invite */
  @Post('invite/:token/accept')
  acceptInvite(@Param('token') token: string, @Req() req: Request) {
    return this.fleetDriverService.acceptInvite(token, req.user.id);
  }

  /**
   * BGC vendor webhook — called by the background check provider when a check completes.
   * Secured via a shared secret in the X-BGC-Webhook-Secret header.
   * Replace BGC_WEBHOOK_SECRET with the value from your BGC vendor's dashboard.
   */
  @Public()
  @Post('bgc/webhook')
  async bgcWebhook(
    @Headers('x-bgc-webhook-secret') secret: string,
    @Body() body: { fleetDriverId: string; passed: boolean; reason?: string },
  ) {
    const expected = process.env.BGC_WEBHOOK_SECRET;
    if (!expected || secret !== expected) {
      throw new UnauthorizedException('Invalid webhook secret');
    }
    return this.fleetDriverService.completeBackgroundCheck(
      body.fleetDriverId,
      body.passed,
      body.reason,
    );
  }
}

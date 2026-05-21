import {
  Controller,
  Post,
  Get,
  Patch,
  Param,
  Body,
  Req,
  UseGuards,
  Query,
  Headers,
  RawBodyRequest,
  BadRequestException,
  Logger,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/role.guard';
import { FleetManagerGuard } from '../guards/fleet-manager.guard';
import { Public } from '../../common/decorators/public.decorator';
import { FleetRegistrationService } from '../services/fleet-registration.service';
import { FleetAnalyticsService } from '../services/fleet-analytics.service';
import { FleetPayoutService } from '../services/fleet-payout.service';
import { CreateFleetDto } from '../dto/create-fleet.dto';
import { UpdateFleetDto } from '../dto/update-fleet.dto';
import { FleetAnalyticsQueryDto } from '../dto/fleet-query.dto';

@Controller('fleet')
@UseGuards(AuthGuard, RolesGuard)
export class FleetController {
  private readonly logger = new Logger(FleetController.name);

  constructor(
    private readonly fleetRegistrationService: FleetRegistrationService,
    private readonly fleetAnalyticsService: FleetAnalyticsService,
    private readonly fleetPayoutService: FleetPayoutService,
  ) {}

  /** Fleet Manager: register a new fleet company */
  @Post('register')
  register(@Req() req: Request, @Body() dto: CreateFleetDto) {
    return this.fleetRegistrationService.registerFleet(req.user.id, dto);
  }

  /** Fleet Manager: initiate Stripe Connect onboarding */
  @Post(':fleetId/stripe-onboarding')
  @UseGuards(FleetManagerGuard)
  stripeOnboarding(@Param('fleetId') fleetId: string, @Req() req: Request) {
    return this.fleetRegistrationService.initiateStripeOnboarding(fleetId, req.user.id);
  }

  /** Get fleet profile */
  @Get(':fleetId')
  findOne(@Param('fleetId') fleetId: string) {
    return this.fleetRegistrationService.findById(fleetId);
  }

  /** Fleet Manager: update fleet profile */
  @Patch(':fleetId')
  @UseGuards(FleetManagerGuard)
  update(@Param('fleetId') fleetId: string, @Body() dto: UpdateFleetDto) {
    return this.fleetRegistrationService.updateFleet(fleetId, dto);
  }

  /** Fleet Manager: get analytics dashboard */
  @Get(':fleetId/analytics')
  @UseGuards(FleetManagerGuard)
  analytics(@Param('fleetId') fleetId: string, @Query() query: FleetAnalyticsQueryDto) {
    const days = parseInt(query.days ?? '30', 10);
    return this.fleetAnalyticsService.getFleetAnalytics(fleetId, days);
  }

  /** Fleet Manager: get payout history */
  @Get(':fleetId/payouts')
  @UseGuards(FleetManagerGuard)
  payouts(
    @Param('fleetId') fleetId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
  ) {
    return this.fleetPayoutService.getPayoutHistory(fleetId, +page, +limit);
  }

  /** Fleet Manager: get driver performance */
  @Get(':fleetId/drivers/:driverUserId/performance')
  @UseGuards(FleetManagerGuard)
  driverPerformance(
    @Param('fleetId') fleetId: string,
    @Param('driverUserId') driverUserId: string,
    @Query() query: FleetAnalyticsQueryDto,
  ) {
    const days = parseInt(query.days ?? '30', 10);
    return this.fleetAnalyticsService.getDriverPerformance(fleetId, driverUserId, days);
  }

  /**
   * Stripe Connect webhook — receives `account.updated` events when a fleet manager
   * completes Stripe onboarding and payouts become enabled.
   * Verify using STRIPE_CONNECT_WEBHOOK_SECRET from your Stripe dashboard.
   */
  @Public()
  @Post('stripe/webhook')
  async stripeConnectWebhook(
    @Headers('stripe-signature') signature: string,
    @Req() req: RawBodyRequest<Request>,
  ) {
    const webhookSecret = process.env.STRIPE_CONNECT_WEBHOOK_SECRET;
    if (!webhookSecret) {
      this.logger.error('STRIPE_CONNECT_WEBHOOK_SECRET is not configured');
      throw new BadRequestException('Webhook secret not configured');
    }

    // Verify Stripe signature using raw body
    let event: { type: string; data: { object: Record<string, unknown> } };
    try {
      const stripe = (await import('stripe')).default;
      const stripeClient = new stripe(process.env.STRIPE_SECRET_KEY ?? '', { apiVersion: '2024-06-20' as never });
      event = stripeClient.webhooks.constructEvent(
        req.rawBody ?? Buffer.alloc(0),
        signature,
        webhookSecret,
      ) as typeof event;
    } catch (err) {
      this.logger.warn(`Stripe webhook signature verification failed: ${err.message}`);
      throw new BadRequestException('Invalid Stripe webhook signature');
    }

    if (event.type === 'account.updated') {
      const account = event.data.object as { id: string; payouts_enabled: boolean };
      await this.fleetRegistrationService.handleStripeAccountUpdated(account.id, account.payouts_enabled);
    }

    return { received: true };
  }
}

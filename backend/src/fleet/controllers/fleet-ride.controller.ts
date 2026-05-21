import {
  Controller,
  Post,
  Get,
  Delete,
  Param,
  Body,
  Req,
  Query,
  UseGuards,
  ParseFloatPipe,
} from '@nestjs/common';
import { Request } from 'express';
import { AuthGuard } from '../../common/guards/auth.guard';
import { RolesGuard } from '../../common/guards/role.guard';
import { FleetManagerGuard } from '../guards/fleet-manager.guard';
import { FleetRideService } from '../services/fleet-ride.service';
import { BookFleetRideDto } from '../dto/fleet-ride.dto';

@Controller('fleet')
@UseGuards(AuthGuard, RolesGuard)
export class FleetRideController {
  constructor(private readonly fleetRideService: FleetRideService) {}

  // ───────────── Tribe Discovery & Membership ─────────────

  /** Rider: discover all public fleet tribes */
  @Get('tribes')
  discoverTribes(@Query('page') page = '1', @Query('limit') limit = '20') {
    return this.fleetRideService.discoverFleetTribes(+page, +limit);
  }

  /** Rider: request to join a fleet tribe */
  @Post('tribes/:tribeId/join')
  joinTribe(@Param('tribeId') tribeId: string, @Req() req: Request) {
    return this.fleetRideService.joinFleetTribe(req.user.id, tribeId);
  }

  /** Fleet Manager: approve a rider's join request */
  @Post('tribes/:tribeId/members/:riderId/approve')
  approveMember(
    @Param('tribeId') tribeId: string,
    @Param('riderId') riderId: string,
    @Req() req: Request,
  ) {
    return this.fleetRideService.approveRiderJoinRequest(req.user.id, tribeId, riderId);
  }

  /** Fleet Manager: remove a rider from the tribe */
  @Delete('tribes/:tribeId/members/:riderId')
  removeMember(
    @Param('tribeId') tribeId: string,
    @Param('riderId') riderId: string,
    @Req() req: Request,
  ) {
    return this.fleetRideService.removeRiderFromTribe(req.user.id, tribeId, riderId);
  }

  // ───────────── Ride Booking ─────────────

  /** Fleet Manager / Driver: list rides for a fleet */
  @Get(':fleetId/rides')
  @UseGuards(FleetManagerGuard)
  listRides(
    @Param('fleetId') fleetId: string,
    @Query('page') page = '1',
    @Query('limit') limit = '20',
    @Query('status') status?: string,
  ) {
    return this.fleetRideService.listFleetRides(fleetId, +page, +limit, status);
  }

  /** Rider: book a fleet ride */
  @Post('rides')
  bookRide(@Req() req: Request, @Body() dto: BookFleetRideDto) {
    return this.fleetRideService.bookFleetRide(req.user.id, dto);
  }

  /** Driver: accept a fleet ride assignment */
  @Post('rides/:rideId/accept')
  acceptRide(@Param('rideId') rideId: string, @Req() req: Request) {
    return this.fleetRideService.acceptRide(rideId, req.user.id);
  }

  /** Driver: decline a fleet ride assignment */
  @Post('rides/:rideId/decline')
  declineRide(@Param('rideId') rideId: string, @Req() req: Request) {
    return this.fleetRideService.declineRide(rideId, req.user.id);
  }

  /** Driver: mark ride as completed */
  @Post('rides/:rideId/complete')
  completeRide(@Param('rideId') rideId: string, @Req() req: Request) {
    return this.fleetRideService.completeRide(rideId, req.user.id);
  }

  /** Rider/Driver: get a single ride by ID (for status polling) */
  @Get('rides/:rideId')
  getRide(@Param('rideId') rideId: string) {
    return this.fleetRideService.getRide(rideId);
  }

  /** Rider: estimate fare before booking */
  @Get('rides/estimate')
  estimateFare(
    @Query('pickup_lat', ParseFloatPipe) pickupLat: number,
    @Query('pickup_lng', ParseFloatPipe) pickupLng: number,
    @Query('dropoff_lat', ParseFloatPipe) dropoffLat: number,
    @Query('dropoff_lng', ParseFloatPipe) dropoffLng: number,
    @Query('fleet_id') fleetId: string,
  ) {
    return this.fleetRideService.estimateFare(pickupLat, pickupLng, dropoffLat, dropoffLng, fleetId);
  }

  /** Places autocomplete proxy — keeps Google API key server-side */
  @Get('places/autocomplete')
  autocomplete(@Query('input') input: string) {
    return this.fleetRideService.searchPlaces(input);
  }

  /** Places details proxy — resolve a place_id to coordinates */
  @Get('places/details')
  placeDetails(@Query('place_id') placeId: string) {
    return this.fleetRideService.getPlaceDetails(placeId);
  }
}

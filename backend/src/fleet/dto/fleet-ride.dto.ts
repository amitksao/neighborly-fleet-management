import { IsDateString, IsNotEmpty, IsNumber, IsString, IsUUID } from 'class-validator';

export class BookFleetRideDto {
  @IsNotEmpty()
  @IsUUID()
  fleet_tribe_id: string;

  @IsNotEmpty()
  @IsNumber()
  pickup_latitude: number;

  @IsNotEmpty()
  @IsNumber()
  pickup_longitude: number;

  @IsNotEmpty()
  @IsString()
  pickup_address: string;

  @IsNotEmpty()
  @IsNumber()
  dropoff_latitude: number;

  @IsNotEmpty()
  @IsNumber()
  dropoff_longitude: number;

  @IsNotEmpty()
  @IsString()
  dropoff_address: string;

  @IsNotEmpty()
  @IsDateString()
  scheduled_at: string;
}

export class RespondFleetRideDto {
  // No body needed — action is encoded in the endpoint (accept/decline)
}

export class ApproveRiderMembershipDto {
  // Rider userId is a path param; no body required
}

import { IsEnum, IsInt, IsOptional, IsString, Max, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { FleetStatus } from '../entities/fleet.entity';
import { FleetDriverStatus } from '../entities/fleet-driver.entity';

export class FleetQueryDto {
  @IsOptional()
  @IsEnum(FleetStatus)
  status?: FleetStatus;

  @IsOptional()
  @IsString()
  search?: string;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

export class FleetDriverQueryDto {
  @IsOptional()
  @IsEnum(FleetDriverStatus)
  status?: FleetDriverStatus;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  page?: number = 1;

  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  @Max(100)
  limit?: number = 20;
}

export class FleetAnalyticsQueryDto {
  @IsOptional()
  @IsEnum(['30', '60', '90'])
  days?: '30' | '60' | '90' = '30';
}

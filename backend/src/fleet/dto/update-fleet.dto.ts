import { IsEmail, IsNumber, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class UpdateFleetDto {
  @IsOptional()
  @IsString()
  @MaxLength(200)
  company_name?: string;

  @IsOptional()
  @IsEmail()
  company_email?: string;

  @IsOptional()
  @IsString()
  @MaxLength(20)
  company_phone?: string;

  @IsOptional()
  @IsString()
  company_address?: string;

  @IsOptional()
  @IsString()
  logo_url?: string;

  @IsOptional()
  @IsString()
  description?: string;
}

export class SetFleetFeeDto {
  @IsNumber()
  @Min(0)
  @Max(100)
  platform_fee_pct: number;
}

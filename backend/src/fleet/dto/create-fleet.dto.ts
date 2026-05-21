import { IsEmail, IsNotEmpty, IsOptional, IsString, MaxLength } from 'class-validator';

export class CreateFleetDto {
  @IsNotEmpty()
  @IsString()
  @MaxLength(200)
  company_name: string;

  @IsNotEmpty()
  @IsEmail()
  company_email: string;

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

import { IsEmail, IsNotEmpty, IsOptional, IsString } from 'class-validator';

export class InviteDriverDto {
  @IsNotEmpty()
  @IsEmail()
  email: string;

  @IsOptional()
  @IsString()
  message?: string;
}

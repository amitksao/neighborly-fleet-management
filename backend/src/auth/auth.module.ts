import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AuthService } from './auth.service';
import { AuthController } from './auth.controller';
import { User } from '../users/entities/user.entity';
import { Fleet } from '../fleet/entities/fleet.entity';
import { EmailModule } from '../common/module/email.module';

@Module({
  imports: [TypeOrmModule.forFeature([User, Fleet]), EmailModule],
  controllers: [AuthController],
  providers: [AuthService],
})
export class AuthModule {}

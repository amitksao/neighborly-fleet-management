import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { env } from '../config/env';
import { StripeConnectAccount } from './entities/stripe-connect-account.entity';
import { StripeService } from './services/stripe.service';
import { StripeConnectService } from './services/stripe-connect.service';
import { User } from '../users/entities/user.entity';
import { UsersModule } from '../users/users.module';

@Module({
  imports: [
    TypeOrmModule.forFeature([StripeConnectAccount, User]),
    JwtModule.register({
      secret: env.JWT_SECRET,
      signOptions: { expiresIn: '6h' },
    }),
    forwardRef(() => UsersModule),
  ],
  providers: [StripeService, StripeConnectService],
  exports: [StripeService, StripeConnectService],
})
export class StripeModule {}

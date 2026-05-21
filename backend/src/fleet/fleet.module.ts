import { Module, forwardRef } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';

// Entities from this module
import { Fleet } from './entities/fleet.entity';
import { FleetDriver } from './entities/fleet-driver.entity';
import { FleetInvite } from './entities/fleet-invite.entity';

// Entities from existing backend modules
import { Ride } from '../rides/entities/ride.entity';
import { Community } from '../communities/entities/community.entity';
import { User } from '../users/entities/user.entity';
import { StripeConnectAccount } from '../stripe/entities/stripe-connect-account.entity';

// Services
import { FleetRegistrationService } from './services/fleet-registration.service';
import { FleetDriverService } from './services/fleet-driver.service';
import { FleetRideService } from './services/fleet-ride.service';
import { FleetPayoutService } from './services/fleet-payout.service';
import { FleetAnalyticsService } from './services/fleet-analytics.service';

// Controllers
import { FleetController } from './controllers/fleet.controller';
import { FleetAdminController } from './controllers/fleet-admin.controller';
import { FleetDriverController } from './controllers/fleet-driver.controller';
import { FleetRideController } from './controllers/fleet-ride.controller';

// Guards
import { FleetManagerGuard } from './guards/fleet-manager.guard';

// Existing modules
import { StripeModule } from '../stripe/stripe.module';
import { UsersModule } from '../users/users.module';
import { RedisModule } from '../common/module/redis.module';
import { EmailModule } from '../common/module/email.module';
import { NotificationModule } from '../common/module/notification.module';
import { GooglePlacesModule } from '../google-places/google-places.module';
import { env } from '../config/env';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Fleet,
      FleetDriver,
      FleetInvite,
      Ride,
      Community,
      User,
      StripeConnectAccount,
    ]),
    JwtModule.register({
      secret: env.JWT_SECRET,
      signOptions: { expiresIn: '6h' },
    }),
    forwardRef(() => StripeModule),
    forwardRef(() => UsersModule),
    RedisModule,
    EmailModule,
    NotificationModule,
    GooglePlacesModule,
  ],
  controllers: [
    FleetController,
    FleetAdminController,
    FleetDriverController,
    FleetRideController,
  ],
  providers: [
    FleetRegistrationService,
    FleetDriverService,
    FleetRideService,
    FleetPayoutService,
    FleetAnalyticsService,
    FleetManagerGuard,
  ],
  exports: [FleetRegistrationService, FleetDriverService, FleetRideService],
})
export class FleetModule {}

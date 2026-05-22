import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ScheduleModule } from '@nestjs/schedule';
import { JwtModule } from '@nestjs/jwt';
import typeorm from './config/typeorm';
import { env } from './config/env';

import { RedisModule } from './common/module/redis.module';
import { NotificationModule } from './common/module/notification.module';
import { EmailModule } from './common/module/email.module';
import { UsersModule } from './users/users.module';
import { StripeModule } from './stripe/stripe.module';
import { GooglePlacesModule } from './google-places/google-places.module';
import { FleetModule } from './fleet/fleet.module';
import { AuthModule } from './auth/auth.module';
import { HealthController } from './health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true,
      load: [typeorm],
    }),
    ScheduleModule.forRoot(),
    TypeOrmModule.forRootAsync({
      imports: [ConfigModule],
      useFactory: (configService: ConfigService) => configService.get('typeorm'),
      inject: [ConfigService],
    }),
    JwtModule.register({
      global: true,
      secret: env.JWT_SECRET,
      signOptions: { expiresIn: '6h' },
    }),
    RedisModule,
    NotificationModule,
    EmailModule,
    UsersModule,
    StripeModule,
    GooglePlacesModule,
    FleetModule,
    AuthModule,
  ],
  controllers: [HealthController],
})
export class AppModule {}

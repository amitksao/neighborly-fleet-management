import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
  Logger,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';
import { env } from '../../config/env';
import { UsersService } from '../../users/users.service';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly logger = new Logger(AuthGuard.name);

  constructor(
    private jwtService: JwtService,
    private usersService: UsersService,
    private reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const request = context.switchToHttp().getRequest();
    const token = this.extractTokenFromHeader(request);

    if (!token) {
      throw new UnauthorizedException('Authorization token required');
    }

    try {
      const payload = await this.jwtService.verifyAsync(token, {
        secret: env.JWT_SECRET,
      });

      if (!payload || !payload.id) {
        throw new UnauthorizedException('Invalid token payload');
      }

      let user = await this.usersService.findOne(payload.id);
      if (!user) {
        throw new UnauthorizedException('User not found');
      }

      const timezoneHeader = request.headers['x-timezone'] ?? request.headers['time-zone'];
      const timezoneFromRequest =
        typeof timezoneHeader === 'string'
          ? timezoneHeader
          : Array.isArray(timezoneHeader)
          ? timezoneHeader[0]
          : undefined;
      if (timezoneFromRequest?.trim()) {
        user = await this.usersService.updateTimezone(user.id, timezoneFromRequest);
      }

      request['user'] = user;
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) throw error;
      if (error.name === 'TokenExpiredError') throw new UnauthorizedException('Token expired');
      if (error.name === 'JsonWebTokenError') throw new UnauthorizedException('Invalid token');
      throw new UnauthorizedException('Authentication failed');
    }
  }

  private extractTokenFromHeader(request: Request): string | undefined {
    const [type, token] = request.headers.authorization?.split(' ') ?? [];
    return type === 'Bearer' ? token : undefined;
  }
}

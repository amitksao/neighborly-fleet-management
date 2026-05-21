import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { UserRole } from '../enum/roles.enum';
import { ROLES_KEY } from '../decorators/roles.decorator';

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const requiredRoles = this.reflector.getAllAndOverride<UserRole[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);

    if (!requiredRoles) return true;

    const request = context.switchToHttp().getRequest();
    const user = request.user;

    if (user?.role === UserRole.ADMIN) return true;

    if (!user || !user.role) {
      throw new UnauthorizedException('User is not authenticated');
    }

    if (!requiredRoles.includes(user.role)) {
      throw new UnauthorizedException(
        `Role ${user.role} is not allowed. Required: ${requiredRoles.join(', ')}`,
      );
    }

    return true;
  }
}

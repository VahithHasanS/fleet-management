import {
  CanActivate,
  ExecutionContext,
  ForbiddenException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { JwtService } from '@nestjs/jwt';
import { IS_PUBLIC_KEY, PERMISSIONS_KEY, ROLES_KEY } from './decorators';
import { ROLE_PERMISSIONS, Role } from './constants';
import { AuthUser } from './types';

@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwt: JwtService,
    private readonly reflector: Reflector,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (isPublic) return true;

    const req = context.switchToHttp().getRequest();
    const auth = req.headers?.authorization as string | undefined;
    const token = auth?.startsWith('Bearer ') ? auth.slice(7) : undefined;
    if (!token) throw new UnauthorizedException('Missing bearer token');

    try {
      const payload = await this.jwt.verifyAsync(token);
      req.user = payload.user as AuthUser;
      return true;
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }
  }
}

@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<Role[]>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;
    const user = context.switchToHttp().getRequest().user as AuthUser;
    if (!required.includes(user.role as Role)) {
      throw new ForbiddenException(`Role ${user.role} not allowed here`);
    }
    return true;
  }
}

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<string[]>(PERMISSIONS_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required || required.length === 0) return true;
    const user = context.switchToHttp().getRequest().user as AuthUser;
    const granted = ROLE_PERMISSIONS[user.role as Role] ?? [];
    const ok = required.every((p) => granted.includes(p as never));
    if (!ok) throw new ForbiddenException(`Missing permission: ${required.join(', ')}`);
    return true;
  }
}

/**
 * Enforces that the :tenantId path/wildcard belongs to the authenticated user's
 * tenant. SUPER_ADMIN may pass any tenant scope.
 */
@Injectable()
export class TenantGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest();
    const user = req.user as AuthUser;
    const tenantId = req.params?.tenantId as string | undefined;
    if (!tenantId) return true;
    if (user.role === 'SUPER_ADMIN') return true;
    if (!user.tenantId || user.tenantId !== tenantId) {
      throw new ForbiddenException('Tenant scope mismatch');
    }
    return true;
  }
}
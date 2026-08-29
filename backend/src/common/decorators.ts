import { SetMetadata, createParamDecorator, ExecutionContext } from '@nestjs/common';
import { Permission, Role } from './constants';
import { AuthUser } from './types';

export const IS_PUBLIC_KEY = 'isPublic';
export const ROLES_KEY = 'roles';
export const PERMISSIONS_KEY = 'permissions';

export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
export const Roles = (...roles: Role[]) => SetMetadata(ROLES_KEY, roles);
export const Permissions = (...perms: Permission[]) => SetMetadata(PERMISSIONS_KEY, perms);

export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext): AuthUser | unknown => {
    const req = ctx.switchToHttp().getRequest();
    return data ? req.user?.[data] : req.user;
  },
);

export const TenantParam = createParamDecorator(
  (data: unknown, ctx: ExecutionContext): string | undefined => {
    const req = ctx.switchToHttp().getRequest();
    return req.params?.tenantId;
  },
);
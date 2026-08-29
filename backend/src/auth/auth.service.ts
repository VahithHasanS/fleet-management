import { Inject, Injectable } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectModel } from '@nestjs/mongoose';
import { Model } from 'mongoose';
import { Redis } from 'ioredis';
import { randomUUID } from 'crypto';
import { REDIS } from '../database/database.module';
import { User, UserDoc } from '../database/schemas';
import { AuthUser } from '../common/types';
import { verifyPassword } from './password';

@Injectable()
export class AuthService {
  constructor(
    @InjectModel(User.name) private readonly users: Model<UserDoc>,
    private readonly jwt: JwtService,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async validateLogin(email: string, password: string): Promise<UserDoc> {
    const user = await this.users.findOne({ email: email.toLowerCase().trim() });
    if (!user) throw new Error('INVALID_CREDENTIALS');
    const ok = verifyPassword(password, user.salt, user.passwordHash);
    if (!ok) throw new Error('INVALID_CREDENTIALS');
    return user;
  }

  toAuthUser(user: UserDoc): AuthUser {
    return {
      userId: String(user._id),
      email: user.email,
      role: user.role,
      tenantId: user.tenantId ? String(user.tenantId) : undefined,
      name: user.displayName,
      driverId: user.driverId ? String(user.driverId) : undefined,
    };
  }

  private async issueTokens(user: UserDoc) {
    const accessToken = await this.jwt.signAsync({ user: this.toAuthUser(user) });
    const refreshToken = randomUUID().replace(/-/g, '');
    const userId = String(user._id);
    // Rotating, single-use refresh token: latest per user, plus reverse lookup.
    await this.redis.set(`refresh:${userId}`, refreshToken, 'EX', 60 * 60 * 24 * 7);
    await this.redis.set(`rt:${refreshToken}`, userId, 'EX', 60 * 60 * 24 * 7);
    return { accessToken, refreshToken, expiresIn: 60 * 15 };
  }

  async login(email: string, password: string) {
    const user = await this.validateLogin(email, password);
    const tokens = await this.issueTokens(user);
    return { ...tokens, user: this.toAuthUser(user) };
  }

  async refresh(refreshToken: string) {
    const userId = await this.redis.get(`rt:${refreshToken}`);
    if (!userId) throw new Error('INVALID_REFRESH');
    const stored = await this.redis.get(`refresh:${userId}`);
    if (!stored || stored !== refreshToken) throw new Error('INVALID_REFRESH');
    const user = await this.users.findById(userId);
    if (!user) throw new Error('INVALID_REFRESH');
    // Rotate: invalidate old, mint new.
    await this.redis.del(`rt:${refreshToken}`);
    await this.redis.del(`refresh:${userId}`);
    const tokens = await this.issueTokens(user);
    return { ...tokens, user: this.toAuthUser(user) };
  }

  async logout(userId: string) {
    await this.redis.del(`refresh:${userId}`);
  }

  async deviceToken(userId: string, tenantId: string, role = 'DRIVER'): Promise<string> {
    return this.jwt.signAsync({
      user: { userId, tenantId, role, email: 'device@ghost.local', name: 'device' },
    });
  }
}
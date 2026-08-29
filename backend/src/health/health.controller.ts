import { Controller, Get } from '@nestjs/common';
import { InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';
import { Inject, Injectable } from '@nestjs/common';
import Redis from 'ioredis';
import { REDIS } from '../database/database.module';
import { Public } from '../common/decorators';

@Injectable()
export class HealthService {
  constructor(
    @InjectConnection() private readonly connection: Connection,
    @Inject(REDIS) private readonly redis: Redis,
  ) {}

  async check() {
    let mongo = 'up';
    try {
      await this.connection.db?.admin().ping();
    } catch {
      mongo = 'down';
    }
    let redis = 'up';
    try {
      await this.redis.ping();
    } catch {
      redis = 'down';
    }
    return {
      status: mongo === 'up' && redis === 'up' ? 'ok' : 'degraded',
      uptimeSec: Math.round(process.uptime()),
      mongo,
      redis,
      now: new Date().toISOString(),
    };
  }
}

@Controller('api/v1/health')
export class HealthController {
  constructor(private readonly health: HealthService) {}

  @Public()
  @Get()
  check() {
    return this.health.check();
  }
}
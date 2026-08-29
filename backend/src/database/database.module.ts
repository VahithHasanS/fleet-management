import { Global, Injectable, Module, OnApplicationBootstrap } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { MongooseModule, InjectConnection } from '@nestjs/mongoose';
import { Connection } from 'mongoose';
import Redis from 'ioredis';
import { MODELS } from './schemas';

export const REDIS = 'REDIS_CLIENT';

@Injectable()
export class DatabaseBootstrap implements OnApplicationBootstrap {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  async onApplicationBootstrap(): Promise<void> {
    const db = this.connection.db;
    if (!db) return;
    // Monotonic telemetry bucket: native MongoDB time-series collection.
    try {
      await db.createCollection('telemetrypoints', {
        timeseries: { timeField: 'ts', metaField: 'meta', granularity: 'seconds' },
      });
    } catch (err) {
      // E11000 duplicate — collection already exists, fine.
    }
    try {
      await db
        .collection('telemetrypoints')
        .createIndex({ 'meta.vehicleId': 1, ts: -1 });
    } catch {
      /* ignore */
    }
    // Deliberately do NOT close the mongoose connection on SIGTERM: a forced
    // close while a simulator tick query is in flight turns the pending query
    // into an unhandled rejection and crashes the process mid-shutdown.
    // Process exit releases the sockets anyway.
  }
}

@Injectable()
export class TelemetrySeries {
  constructor(@InjectConnection() private readonly connection: Connection) {}

  get collection() {
    return this.connection.collection('telemetrypoints');
  }

  async insertPoints(
    rows: Array<{
      ts: Date;
      meta: { vehicleId: string; tenantId: string; tripId?: string };
      lat: number;
      lon: number;
      spd: number;
      hdg: number;
      acc: number;
      la?: number;
      yaw?: number;
      conf: number;
    }>,
  ): Promise<void> {
    if (rows.length === 0) return;
    await this.collection.insertMany(rows as never, { ordered: false });
  }

  async recent(
    tenantId: string,
    vehicleId: string,
    limit = 500,
  ): Promise<unknown[]> {
    return this.collection
      .find({ 'meta.tenantId': tenantId, 'meta.vehicleId': vehicleId })
      .sort({ ts: -1 })
      .limit(limit)
      .toArray();
  }
}

@Global()
@Module({
  imports: [
    MongooseModule.forRootAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        uri: config.get<string>('MONGO_URI', 'mongodb://localhost:27017/ghosttelemetry'),
      }),
    }),
    MongooseModule.forFeature(MODELS),
  ],
  providers: [
    {
      provide: REDIS,
      useFactory: (config: ConfigService) =>
        new Redis(config.get<string>('REDIS_URL', 'redis://localhost:6379'), {
          maxRetriesPerRequest: 3,
          enableReadyCheck: false,
        }),
      inject: [ConfigService],
    },
    DatabaseBootstrap,
    TelemetrySeries,
  ],
  exports: [MongooseModule, REDIS, TelemetrySeries],
})
export class DatabaseModule {}
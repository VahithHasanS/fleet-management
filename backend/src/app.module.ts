import { Module } from '@nestjs/common';
import { APP_GUARD } from '@nestjs/core';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './auth/auth.module';
import { TelemetryModule } from './telemetry/telemetry.module';
import { ProcessingModule } from './processing/processing.module';
import { DomainModule } from './domain/domain.module';
import { SimulatorModule } from './simulator/simulator.module';
import { SeedModule } from './seed/seed.module';
import { DriverOperationsModule } from './driver-operations/driver-operations.module';
import { MaintenanceModule } from './maintenance/maintenance.module';
import { VideoTelematicsModule } from './video-telematics/video-telematics.module';
import { InsightsModule } from './insights/insights.module';
import { HealthController, HealthService } from './health/health.controller';
import { JwtAuthGuard, PermissionsGuard, RolesGuard } from './common/guards';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    DatabaseModule,
    AuthModule,
    TelemetryModule,
    ProcessingModule,
    DomainModule,
    SimulatorModule,
    SeedModule,
    DriverOperationsModule,
    MaintenanceModule,
    VideoTelematicsModule,
    InsightsModule,
  ],
  controllers: [HealthController],
  providers: [
    HealthService,
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
  ],
})
export class AppModule {}
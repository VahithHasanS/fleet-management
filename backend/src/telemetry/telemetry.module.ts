import { Global, Module } from '@nestjs/common';
import { TelemetryGateway } from './telemetry.gateway';
import { TelemetryService } from './telemetry.service';
import { LiveService } from './live.service';
import { VehicleResolver } from './vehicle-resolver';
import { PubSub } from '../common/pubsub';
import { VideoTelematicsModule } from '../video-telematics/video-telematics.module';

@Global()
@Module({
  imports: [VideoTelematicsModule],
  providers: [TelemetryGateway, TelemetryService, LiveService, VehicleResolver, PubSub],
  exports: [TelemetryService, LiveService, VehicleResolver, PubSub],
})
export class TelemetryModule {}
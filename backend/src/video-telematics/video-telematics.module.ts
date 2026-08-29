import { Module } from '@nestjs/common';
import { VideoTelematicsController } from './video-telematics.controller';
import { VideoTelematicsService } from './video-telematics.service';

@Module({
  controllers: [VideoTelematicsController],
  providers: [VideoTelematicsService],
  exports: [VideoTelematicsService],
})
export class VideoTelematicsModule {}

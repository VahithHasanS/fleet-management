import { Module } from '@nestjs/common';
import { DriverOperationsController } from './driver-operations.controller';
import { DriverOperationsService } from './driver-operations.service';

@Module({
  controllers: [DriverOperationsController],
  providers: [DriverOperationsService],
})
export class DriverOperationsModule {}
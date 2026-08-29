import { Module } from '@nestjs/common';
import { TripProcessor } from './processor';

@Module({
  providers: [TripProcessor],
})
export class ProcessingModule {}
import { Controller, Get, Post, Query, UseGuards, Body } from '@nestjs/common';
import { IsIn, IsNumber, IsOptional, IsString, Max, Min } from 'class-validator';
import { CurrentUser, Permissions, TenantParam } from '../common/decorators';
import { TenantGuard } from '../common/guards';
import { AuthUser } from '../common/types';
import { VideoTelematicsService } from './video-telematics.service';

class RecordBreachDto {
  @IsString() vehicleId: string;
  @IsOptional() @IsString() tripId?: string;
  @IsIn(['drowsiness', 'eye_closure', 'distraction', 'yawning', 'camera_obstructed']) breachType: string;
  @IsIn(['low', 'medium', 'high', 'critical']) severity: string;
  @IsOptional() @IsNumber() durationMs?: number;
  @IsOptional() @IsNumber() @Min(0) @Max(1) confidence?: number;
  @IsOptional() @IsNumber() ear?: number;
  @IsOptional() @IsString() snapshot?: string;
  @IsOptional() @IsString() detail?: string;
}

@Controller('api/v1/tenants/:tenantId/video')
@UseGuards(TenantGuard)
export class VideoTelematicsController {
  constructor(private readonly service: VideoTelematicsService) {}

  @Get('breaches')
  @Permissions('video.read')
  list(
    @TenantParam() tenantId: string,
    @Query('vehicleId') vehicleId?: string,
    @Query('breachType') breachType?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
    @Query('limit') limit?: string,
  ) {
    return this.service.list(tenantId, {
      vehicleId,
      breachType,
      from,
      to,
      limit: limit ? Number(limit) : undefined,
    });
  }

  @Get('stats')
  @Permissions('video.read')
  stats(@TenantParam() tenantId: string) {
    return this.service.stats(tenantId);
  }

  /** REST fallback for breach submission (WS is the primary path from the driver app). */
  @Post('breaches')
  @Permissions('video.breach.write')
  record(
    @TenantParam() tenantId: string,
    @CurrentUser() user: AuthUser,
    @Body() body: RecordBreachDto,
  ) {
    void user;
    return this.service.recordBreach({ ...body, tenantId } as never);
  }
}

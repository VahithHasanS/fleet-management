import { BadRequestException, Body, Controller, Get, Post, Query, UseGuards } from '@nestjs/common';
import { IsBoolean, IsIn, IsInt, IsOptional, IsString, Max, Min, ValidateNested, IsArray } from 'class-validator';
import { Type } from 'class-transformer';
import { CurrentUser, Permissions, TenantParam } from '../common/decorators';
import { TenantGuard } from '../common/guards';
import { AuthUser } from '../common/types';
import { DriverOperationsService } from './driver-operations.service';

class HosLogDto {
  @IsOptional() @IsString() vehicleId?: string;
  @IsIn(['off_duty', 'on_duty', 'driving', 'sleeper']) status: string;
  @IsOptional() @IsString() startedAt?: string;
  @IsOptional() @IsString() endedAt?: string;
  @IsOptional() @IsString() note?: string;
}

class DvirItemDto {
  @IsString() name: string;
  @IsIn(['ok', 'defect', 'na']) status: string;
  @IsOptional() @IsString() note?: string;
}

class DvirDto {
  @IsString() vehicleId: string;
  @IsIn(['pre_trip', 'post_trip']) inspectionType: string;
  @IsBoolean() safeToOperate: boolean;
  @IsArray() @ValidateNested({ each: true }) @Type(() => DvirItemDto) items: DvirItemDto[];
  @IsOptional() @IsString() signature?: string;
}

class WellnessDto {
  @IsInt() @Min(1) @Max(5) fatigue: number;
  @IsInt() @Min(1) @Max(5) stress: number;
  @IsInt() @Min(1) @Max(5) hydration: number;
  @IsOptional() @IsString() note?: string;
}

@Controller('api/v1/tenants/:tenantId/driver-operations')
@UseGuards(TenantGuard)
export class DriverOperationsController {
  constructor(private readonly operations: DriverOperationsService) {}

  private driverId(user: AuthUser, requested?: string) {
    return user.role === 'DRIVER' ? user.driverId : requested;
  }

  private requireDriverId(user: AuthUser, requested?: string) {
    const driverId = this.driverId(user, requested);
    if (!driverId) throw new BadRequestException('driverId is required for this role');
    return driverId;
  }

  @Get('hos')
  @Permissions('driver.operations.read')
  logs(@TenantParam() tenantId: string, @CurrentUser() user: AuthUser, @Query('driverId') requested?: string, @Query('from') from?: string, @Query('to') to?: string) {
    const driverId = this.requireDriverId(user, requested);
    return this.operations.listLogs(tenantId, driverId, from, to);
  }

  @Post('hos')
  @Permissions('driver.operations.write')
  createLog(@TenantParam() tenantId: string, @CurrentUser() user: AuthUser, @Body() body: HosLogDto) {
    return this.operations.createLog(tenantId, this.requireDriverId(user), body as never);
  }

  @Get('dvir')
  @Permissions('driver.operations.read')
  dvir(@TenantParam() tenantId: string, @CurrentUser() user: AuthUser, @Query('driverId') requested?: string) {
    return this.operations.listDvir(tenantId, this.requireDriverId(user, requested));
  }

  @Post('dvir')
  @Permissions('driver.operations.write')
  submitDvir(@TenantParam() tenantId: string, @CurrentUser() user: AuthUser, @Body() body: DvirDto) {
    return this.operations.submitDvir(tenantId, this.requireDriverId(user), body as never);
  }

  @Get('wellness')
  @Permissions('driver.operations.read')
  wellness(@TenantParam() tenantId: string, @CurrentUser() user: AuthUser, @Query('driverId') requested?: string) {
    return this.operations.getWellness(tenantId, this.requireDriverId(user, requested));
  }

  @Post('wellness')
  @Permissions('driver.operations.write')
  createWellness(@TenantParam() tenantId: string, @CurrentUser() user: AuthUser, @Body() body: WellnessDto) {
    return this.operations.createWellness(tenantId, this.requireDriverId(user), body);
  }
}
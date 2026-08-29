import { Body, Controller, Get, Post, Put, Query, UseGuards } from '@nestjs/common';
import { IsArray, IsIn, IsISO8601, IsObject, IsOptional, IsString } from 'class-validator';
import { Permissions, TenantParam } from '../common/decorators';
import { TenantGuard } from '../common/guards';
import { InsightsService } from './insights.service';

class OptimizeRouteDto {
  @IsString() vehicleId: string;
  @IsArray() @IsString({ each: true }) stops: string[];
}

class PutSettingsDto {
  @IsObject() data: Record<string, unknown>;
}

@Controller('api/v1/tenants/:tenantId/insights')
@UseGuards(TenantGuard)
export class InsightsController {
  constructor(private readonly insights: InsightsService) {}

  @Get('reports/summary')
  @Permissions('reports.read')
  reportSummary(@TenantParam() tenantId: string, @Query('days') days?: string) {
    return this.insights.reportSummary(tenantId, clampDays(days));
  }

  @Get('reports/daily')
  @Permissions('reports.read')
  reportDaily(@TenantParam() tenantId: string, @Query('days') days?: string) {
    return this.insights.reportDaily(tenantId, clampDays(days));
  }

  @Get('predictive/risks')
  @Permissions('predictive.read')
  predictiveRisks(@TenantParam() tenantId: string) {
    return this.insights.predictiveRisks(tenantId);
  }

  @Get('compliance/summary')
  @Permissions('compliance.read')
  complianceSummary(@TenantParam() tenantId: string) {
    return this.insights.complianceSummary(tenantId);
  }

  @Get('wellness/fleet')
  @Permissions('wellness.read')
  wellnessFleet(@TenantParam() tenantId: string) {
    return this.insights.wellnessFleet(tenantId);
  }

  @Post('route/optimize')
  @Permissions('route.optimize')
  optimizeRoute(@TenantParam() tenantId: string, @Body() body: OptimizeRouteDto) {
    return this.insights.optimizeRoute(tenantId, body.vehicleId, body.stops);
  }

  @Get('settings')
  @Permissions('settings.read')
  getSettings(@TenantParam() tenantId: string) {
    return this.insights.getSettings(tenantId);
  }

  @Put('settings')
  @Permissions('settings.write')
  putSettings(@TenantParam() tenantId: string, @Body() body: PutSettingsDto) {
    return this.insights.putSettings(tenantId, body.data);
  }
}

function clampDays(raw?: string): number {
  const n = Number(raw);
  if (!Number.isFinite(n)) return 7;
  return Math.max(1, Math.min(90, Math.floor(n)));
}

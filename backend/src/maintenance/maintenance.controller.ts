import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { IsIn, IsISO8601, IsNumber, IsOptional, IsString, MinLength } from 'class-validator';
import { Permissions, TenantParam } from '../common/decorators';
import { TenantGuard } from '../common/guards';
import { MaintenanceService } from './maintenance.service';

class CreateMaintenanceDto {
  @IsString() vehicleId: string;
  @IsString() @MinLength(2) title: string;
  @IsIn(['scheduled', 'repair', 'inspection', 'tire', 'oil', 'other']) category: string;
  @IsIn(['low', 'medium', 'high', 'critical']) priority: string;
  @IsISO8601() dueDate: string;
  @IsOptional() @IsNumber() odometerKm?: number;
  @IsOptional() @IsNumber() costInr?: number;
  @IsOptional() @IsString() garage?: string;
  @IsOptional() @IsString() notes?: string;
}

class UpdateMaintenanceDto {
  @IsOptional() @IsIn(['open', 'in_progress', 'completed']) status?: string;
  @IsOptional() @IsIn(['low', 'medium', 'high', 'critical']) priority?: string;
  @IsOptional() @IsISO8601() dueDate?: string;
  @IsOptional() @IsNumber() costInr?: number;
  @IsOptional() @IsNumber() odometerKm?: number;
  @IsOptional() @IsString() garage?: string;
  @IsOptional() @IsString() notes?: string;
}

@Controller('api/v1/tenants/:tenantId/maintenance')
@UseGuards(TenantGuard)
export class MaintenanceController {
  constructor(private readonly service: MaintenanceService) {}

  @Get()
  @Permissions('maintenance.read')
  list(
    @TenantParam() tenantId: string,
    @Query('status') status?: string,
    @Query('vehicleId') vehicleId?: string,
    @Query('from') from?: string,
    @Query('to') to?: string,
  ) {
    return this.service.list(tenantId, { status, vehicleId, from, to });
  }

  @Post()
  @Permissions('maintenance.write')
  create(@TenantParam() tenantId: string, @Body() body: CreateMaintenanceDto) {
    return this.service.create(tenantId, body as never);
  }

  @Patch(':id')
  @Permissions('maintenance.write')
  update(@TenantParam() tenantId: string, @Param('id') id: string, @Body() body: UpdateMaintenanceDto) {
    return this.service.update(tenantId, id, body as Record<string, unknown>);
  }

  @Delete(':id')
  @Permissions('maintenance.write')
  remove(@TenantParam() tenantId: string, @Param('id') id: string) {
    return this.service.remove(tenantId, id);
  }
}

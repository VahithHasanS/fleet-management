import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { IsEmail, IsIn, IsLatitude, IsLongitude, IsNumber, IsOptional, IsString, Max, Min, MinLength } from 'class-validator';
import { TenantGuard } from '../common/guards';
import { Permissions, TenantParam } from '../common/decorators';
import { DomainService } from './domain.service';

class CreateVehicleDto {
  @IsString() @MinLength(2) name: string;
  @IsString() @MinLength(2) plate: string;
  @IsString() @IsIn(['car', 'suv', 'truck', 'bus']) vehicleClass: string;
  @IsOptional() @IsString() fleetId?: string;
  @IsOptional() @IsString() driverId?: string;
  @IsOptional() @IsNumber() @Min(20) @Max(160) speedLimitKmh?: number;
}

class UpdateVehicleDto {
  @IsOptional() @IsString() name?: string;
  @IsOptional() @IsString() plate?: string;
  @IsOptional() @IsIn(['car', 'suv', 'truck', 'bus']) vehicleClass?: string;
  @IsOptional() @IsString() fleetId?: string;
  @IsOptional() @IsString() driverId?: string;
  @IsOptional() @IsNumber() @Min(20) @Max(160) speedLimitKmh?: number;
}

class CreateDriverDto {
  @IsString() @MinLength(2) name: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsEmail() email?: string;
  @IsOptional() @IsString() fleetId?: string;
  @IsOptional() @IsString() avatarColor?: string;
}

class CreateFleetDto {
  @IsString() @MinLength(2) name: string;
  @IsOptional() @IsString() city?: string;
}

class CreateGeofenceDto {
  @IsString() @MinLength(2) name: string;
  @IsNumber() @IsLatitude() centerLat: number;
  @IsNumber() @IsLongitude() centerLon: number;
  @IsNumber() @Min(50) @Max(50_000) radiusM: number;
  @IsOptional() @IsString() color?: string;
}

@Controller('api/v1/tenants/:tenantId')
@UseGuards(TenantGuard)
export class DomainController {
  constructor(private readonly domain: DomainService) {}

  // ---------- vehicles ----------
  @Get('vehicles')
  @Permissions('vehicles.read')
  listVehicles(@TenantParam() tenantId: string, @Query('fleetId') fleetId?: string) {
    return this.domain.listVehicles(tenantId, fleetId);
  }

  @Post('vehicles')
  @Permissions('vehicles.write')
  createVehicle(@TenantParam() tenantId: string, @Body() body: CreateVehicleDto) {
    return this.domain.createVehicle(tenantId, body);
  }

  @Patch('vehicles/:id')
  @Permissions('vehicles.write')
  updateVehicle(@TenantParam() tenantId: string, @Param('id') id: string, @Body() body: UpdateVehicleDto) {
    return this.domain.updateVehicle(tenantId, id, body);
  }

  @Delete('vehicles/:id')
  @Permissions('vehicles.write')
  deleteVehicle(@TenantParam() tenantId: string, @Param('id') id: string) {
    return this.domain.deleteVehicle(tenantId, id);
  }

  // ---------- drivers ----------
  @Get('drivers')
  @Permissions('drivers.read')
  listDrivers(@TenantParam() tenantId: string, @Query('fleetId') fleetId?: string) {
    return this.domain.listDrivers(tenantId, fleetId);
  }

  @Post('drivers')
  @Permissions('drivers.write')
  createDriver(@TenantParam() tenantId: string, @Body() body: CreateDriverDto) {
    return this.domain.createDriver(tenantId, body);
  }

  @Get('leaderboard')
  @Permissions('leaderboard.read')
  leaderboard(@TenantParam() tenantId: string) {
    return this.domain.leaderboard(tenantId);
  }

  // ---------- fleets ----------
  @Get('fleets')
  @Permissions('vehicles.read')
  listFleets(@TenantParam() tenantId: string) {
    return this.domain.listFleets(tenantId);
  }

  @Post('fleets')
  @Permissions('vehicles.write')
  createFleet(@TenantParam() tenantId: string, @Body() body: CreateFleetDto) {
    return this.domain.createFleet(tenantId, body);
  }

  // ---------- geofences ----------
  @Get('geofences')
  @Permissions('geofences.read')
  listGeofences(@TenantParam() tenantId: string) {
    return this.domain.listGeofences(tenantId);
  }

  @Post('geofences')
  @Permissions('geofences.write')
  createGeofence(@TenantParam() tenantId: string, @Body() body: CreateGeofenceDto) {
    return this.domain.createGeofence(tenantId, body);
  }

  @Delete('geofences/:id')
  @Permissions('geofences.write')
  deleteGeofence(@TenantParam() tenantId: string, @Param('id') id: string) {
    return this.domain.deleteGeofence(tenantId, id);
  }

  // ---------- trips / events / alerts ----------
  @Get('trips')
  @Permissions('trips.read')
  listTrips(
    @TenantParam() tenantId: string,
    @Query('driverId') driverId?: string,
    @Query('vehicleId') vehicleId?: string,
    @Query('from') from?: number,
    @Query('to') to?: number,
    @Query('limit') limit?: number,
  ) {
    return this.domain.listTrips(tenantId, { driverId, vehicleId, from, to, limit });
  }

  @Get('trips/:id')
  @Permissions('trips.read')
  getTrip(@TenantParam() tenantId: string, @Param('id') id: string) {
    return this.domain.getTrip(tenantId, id);
  }

  @Get('events')
  @Permissions('events.read')
  listEvents(
    @TenantParam() tenantId: string,
    @Query('type') type?: string,
    @Query('vehicleId') vehicleId?: string,
    @Query('limit') limit?: number,
    @Query('from') from?: number,
    @Query('to') to?: number,
  ) {
    return this.domain.listEvents(tenantId, { type, vehicleId, limit, from, to });
  }

  @Get('alerts')
  @Permissions('events.read')
  listAlerts(@TenantParam() tenantId: string, @Query('limit') limit?: number) {
    return this.domain.listAlerts(tenantId, limit);
  }

  @Patch('alerts/:id/read')
  @Permissions('alerts.read')
  ackAlert(@TenantParam() tenantId: string, @Param('id') id: string) {
    return this.domain.acknowledgeAlert(tenantId, id);
  }

  @Get('stats')
  @Permissions('leaderboard.read')
  stats(@TenantParam() tenantId: string) {
    return this.domain.stats(tenantId);
  }
}
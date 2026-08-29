import { Body, Controller, Get, HttpException, HttpStatus, Param, Post, UseGuards } from '@nestjs/common';
import { IsIn, IsString } from 'class-validator';
import { Permissions } from '../common/decorators';
import { SimulatorService } from './simulator.service';

class TriggerEventDto {
  @IsString()
  @IsIn(['harsh_brake', 'harsh_accel', 'harsh_corner', 'sos', 'wellness_alert'])
  type: string;
}

@Controller('api/v1/simulator')
export class SimulatorController {
  constructor(private readonly sim: SimulatorService) {}

  @Get('status')
  status() {
    return this.sim.status();
  }

  @Post('start')
  @Permissions('simulator.control')
  async start() {
    await this.sim.start();
    return this.sim.status();
  }

  @Post('stop')
  @Permissions('simulator.control')
  stop() {
    this.sim.stop();
    return this.sim.status();
  }

  @Post('reset')
  @Permissions('simulator.control')
  async reset() {
    await this.sim.reset();
    return this.sim.status();
  }

  @Post('vehicles/:vehicleId/event')
  @Permissions('simulator.control')
  async trigger(@Param('vehicleId') vehicleId: string, @Body() body: TriggerEventDto) {
    const ok = await this.sim.triggerEvent(vehicleId, body.type as never);
    if (!ok) throw new HttpException('Unknown simulated vehicle', HttpStatus.NOT_FOUND);
    return { triggered: body.type, vehicleId };
  }
}
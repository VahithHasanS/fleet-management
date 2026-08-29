import { Body, Controller, Get, HttpCode, HttpException, HttpStatus, Post, Req } from '@nestjs/common';
import { ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { IsEmail, IsString } from 'class-validator';
import { CurrentUser, Public } from '../common/decorators';
import { AuthUser } from '../common/types';
import { AuthService } from './auth.service';

export class LoginDto {
  @IsEmail() email!: string;
  @IsString() password!: string;
}

export class RefreshDto {
  @IsString() refreshToken!: string;
}

@ApiTags('auth')
@Controller('api/v1/auth')
export class AuthController {
  constructor(private readonly auth: AuthService) {}

  @Public()
  @Post('login')
  @HttpCode(200)
  @ApiOperation({ summary: 'Login and receive access + refresh tokens' })
  async login(@Body() body: LoginDto) {
    try {
      return await this.auth.login(body.email, body.password);
    } catch (e) {
      const msg = e instanceof Error ? e.message : undefined;
      throw new HttpException(msg ?? 'Login failed', HttpStatus.UNAUTHORIZED);
    }
  }

  @Public()
  @Post('refresh')
  @HttpCode(200)
  @ApiOperation({ summary: 'Rotate refresh token (single-use)' })
  async refresh(@Body() body: RefreshDto) {
    try {
      return await this.auth.refresh(body.refreshToken);
    } catch {
      throw new HttpException('Invalid refresh token', HttpStatus.UNAUTHORIZED);
    }
  }

  @Get('me')
  @ApiOperation({ summary: 'Current authenticated user' })
  me(@CurrentUser() user: AuthUser) {
    return user;
  }
}
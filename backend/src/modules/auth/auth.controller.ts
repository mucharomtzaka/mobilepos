import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';
import { MerchantRegisterDto } from './dto/merchant-register.dto';

@ApiTags('Auth')
@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Login user' })
  @ApiResponse({ status: 200, description: 'Login successful' })
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register new user (kasir/admin)' })
  @ApiResponse({ status: 201, description: 'Registration successful' })
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Post('merchant/register')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ summary: 'Register new merchant' })
  @ApiResponse({ status: 201, description: 'Merchant registration successful' })
  merchantRegister(@Body() dto: MerchantRegisterDto) {
    return this.authService.merchantRegister(dto);
  }
}

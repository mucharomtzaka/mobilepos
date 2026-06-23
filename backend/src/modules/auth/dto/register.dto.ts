import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength, IsOptional, IsIn } from 'class-validator';

export class RegisterDto {
  @ApiProperty()
  @IsString()
  name: string;

  @ApiProperty()
  @IsString()
  username: string;

  @ApiProperty()
  @IsString()
  @MinLength(4)
  password: string;

  @ApiProperty({ enum: ['admin', 'kasir', 'merchant'], default: 'kasir' })
  @IsOptional()
  @IsIn(['admin', 'kasir', 'merchant'])
  role?: string;
}

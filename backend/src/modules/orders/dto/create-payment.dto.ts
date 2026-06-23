import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsIn } from 'class-validator';

export class CreatePaymentDto {
  @ApiProperty({ enum: ['tunai', 'dana', 'ovo', 'gopay', 'transfer', 'qris'] })
  @IsString()
  @IsIn(['tunai', 'dana', 'ovo', 'gopay', 'transfer', 'qris'])
  method: string;

  @ApiProperty()
  @IsNumber()
  amount: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  reference?: string;
}

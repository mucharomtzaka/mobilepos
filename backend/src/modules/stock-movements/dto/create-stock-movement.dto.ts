import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsNumber, IsOptional, IsIn } from 'class-validator';

export class CreateStockMovementDto {
  @ApiProperty()
  @IsNumber()
  productId: number;

  @ApiProperty({ enum: ['in', 'out', 'adjustment'] })
  @IsString()
  @IsIn(['in', 'out', 'adjustment'])
  type: string;

  @ApiProperty()
  @IsNumber()
  qty: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  note?: string;
}

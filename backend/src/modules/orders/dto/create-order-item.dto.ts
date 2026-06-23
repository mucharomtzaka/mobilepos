import { ApiProperty } from '@nestjs/swagger';
import { IsNumber, IsString, IsOptional, Min } from 'class-validator';

export class CreateOrderItemDto {
  @ApiProperty()
  @IsNumber()
  productId: number;

  @ApiProperty()
  @IsString()
  productName: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  variantName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  bundleName?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  bundleId?: number;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsNumber()
  bundleAdjustedPrice?: number;

  @ApiProperty()
  @IsNumber()
  @Min(0)
  price: number;

  @ApiProperty()
  @IsNumber()
  @Min(1)
  qty: number;

  @ApiProperty()
  @IsNumber()
  subtotal: number;
}

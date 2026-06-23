import { ApiProperty } from '@nestjs/swagger';
import { IsOptional } from 'class-validator';

export class SyncPushDto {
  @IsOptional() @ApiProperty({ required: false }) users?: any[];
  @IsOptional() @ApiProperty({ required: false }) categories?: any[];
  @IsOptional() @ApiProperty({ required: false }) products?: any[];
  @IsOptional() @ApiProperty({ required: false }) productVariants?: any[];
  @IsOptional() @ApiProperty({ required: false }) bundles?: any[];
  @IsOptional() @ApiProperty({ required: false }) bundleItems?: any[];
  @IsOptional() @ApiProperty({ required: false }) customers?: any[];
  @IsOptional() @ApiProperty({ required: false }) orders?: any[];
  @IsOptional() @ApiProperty({ required: false }) orderItems?: any[];
  @IsOptional() @ApiProperty({ required: false }) payments?: any[];
  @IsOptional() @ApiProperty({ required: false }) shifts?: any[];
  @IsOptional() @ApiProperty({ required: false }) stockMovements?: any[];
  @IsOptional() @ApiProperty({ required: false }) transactions?: any[];
  @IsOptional() @ApiProperty({ required: false }) tables?: any[];
  @IsOptional() @ApiProperty({ required: false }) settings?: any[];
}

import { ApiProperty } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class SyncPullDto {
  @IsString() @ApiProperty() lastSyncAt: string;

  @IsOptional() @ApiProperty({ required: false }) tables?: string[];
}

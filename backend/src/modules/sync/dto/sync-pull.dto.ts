import { ApiProperty } from '@nestjs/swagger';

export class SyncPullDto {
  @ApiProperty({ description: 'ISO timestamp of last sync' })
  lastSyncAt: string;

  @ApiProperty({ description: 'Optional table filter', required: false })
  tables?: string[];
}

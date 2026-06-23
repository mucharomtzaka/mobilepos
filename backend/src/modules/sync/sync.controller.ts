import { Controller, Post, Body, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { ApiKeyGuard } from './guards/api-key.guard';
import { SyncService } from './sync.service';
import { SyncPullDto } from './dto/sync-pull.dto';
import { SyncPushDto } from './dto/sync-push.dto';

@ApiTags('Sync')
@UseGuards(ApiKeyGuard)
@Controller('sync')
export class SyncController {
  constructor(private syncService: SyncService) {}

  @Post('pull')
  @ApiOperation({ summary: 'Pull changes since last sync' })
  pull(@Body() dto: SyncPullDto) {
    return this.syncService.pull(dto.lastSyncAt, dto.tables);
  }

  @Post('push')
  @ApiOperation({ summary: 'Push local changes to server' })
  push(@Body() dto: SyncPushDto) {
    return this.syncService.push(dto);
  }
}

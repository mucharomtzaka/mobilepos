import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { TablesService } from './tables.service';
import { CreateTableDto } from './dto/create-table.dto';

@ApiTags('Tables')
@Controller('tables')
@UseGuards(JwtAuthGuard)
export class TablesController {
  constructor(private tablesService: TablesService) {}

  @Post()
  @ApiOperation({ summary: 'Create table' })
  create(@Body() dto: CreateTableDto) {
    return this.tablesService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List tables' })
  findAll() {
    return this.tablesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get table by id' })
  findOne(@Param('id') id: string) {
    return this.tablesService.findOne(+id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update table' })
  update(@Param('id') id: string, @Body() dto: CreateTableDto) {
    return this.tablesService.update(+id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete table' })
  remove(@Param('id') id: string) {
    return this.tablesService.remove(+id);
  }
}

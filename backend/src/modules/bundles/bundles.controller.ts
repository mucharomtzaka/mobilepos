import { Controller, Get, Post, Put, Delete, Body, Param, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { BundlesService } from './bundles.service';
import { CreateBundleDto } from './dto/create-bundle.dto';
import { UpdateBundleDto } from './dto/update-bundle.dto';

@ApiTags('Bundles')
@Controller('bundles')
@UseGuards(JwtAuthGuard)
export class BundlesController {
  constructor(private bundlesService: BundlesService) {}

  @Post()
  @ApiOperation({ summary: 'Create bundle' })
  create(@Body() dto: CreateBundleDto) {
    return this.bundlesService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List bundles' })
  findAll() {
    return this.bundlesService.findAll();
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get bundle by id' })
  findOne(@Param('id') id: string) {
    return this.bundlesService.findOne(+id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update bundle' })
  update(@Param('id') id: string, @Body() dto: UpdateBundleDto) {
    return this.bundlesService.update(+id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete bundle' })
  remove(@Param('id') id: string) {
    return this.bundlesService.remove(+id);
  }
}

import { Controller, Get, Post, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { StockMovementsService } from './stock-movements.service';
import { CreateStockMovementDto } from './dto/create-stock-movement.dto';

@ApiTags('Stock Movements')
@Controller('stock-movements')
@UseGuards(JwtAuthGuard)
export class StockMovementsController {
  constructor(private stockMovementsService: StockMovementsService) {}

  @Post()
  @ApiOperation({ summary: 'Create stock movement' })
  create(@Body() dto: CreateStockMovementDto) {
    return this.stockMovementsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List stock movements' })
  findAll(@Query('productId') productId?: string) {
    return this.stockMovementsService.findAll(productId ? +productId : undefined);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get stock movement by id' })
  findOne(@Param('id') id: string) {
    return this.stockMovementsService.findOne(+id);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete stock movement' })
  remove(@Param('id') id: string) {
    return this.stockMovementsService.remove(+id);
  }
}

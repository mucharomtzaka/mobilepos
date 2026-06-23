import { Controller, Get, Post, Put, Delete, Body, Param, Query, UseGuards } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { ProductVariantsService } from './product-variants.service';
import { CreateProductVariantDto } from './dto/create-product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';

@ApiTags('Product Variants')
@Controller('product-variants')
@UseGuards(JwtAuthGuard)
export class ProductVariantsController {
  constructor(private productVariantsService: ProductVariantsService) {}

  @Post()
  @ApiOperation({ summary: 'Create product variant' })
  create(@Body() dto: CreateProductVariantDto) {
    return this.productVariantsService.create(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List product variants' })
  findAll(@Query('productId') productId?: string) {
    return this.productVariantsService.findAll(productId ? +productId : undefined);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get product variant by id' })
  findOne(@Param('id') id: string) {
    return this.productVariantsService.findOne(+id);
  }

  @Put(':id')
  @ApiOperation({ summary: 'Update product variant' })
  update(@Param('id') id: string, @Body() dto: UpdateProductVariantDto) {
    return this.productVariantsService.update(+id, dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Delete product variant' })
  remove(@Param('id') id: string) {
    return this.productVariantsService.remove(+id);
  }
}

import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ProductVariant } from '../../database/entities/product-variant.entity';
import { CreateProductVariantDto } from './dto/create-product-variant.dto';
import { UpdateProductVariantDto } from './dto/update-product-variant.dto';

@Injectable()
export class ProductVariantsService {
  constructor(
    @InjectRepository(ProductVariant)
    private variantRepo: Repository<ProductVariant>,
  ) {}

  async create(dto: CreateProductVariantDto) {
    const variant = this.variantRepo.create({
      ...dto,
      priceAdjustment: dto.priceAdjustment ?? 0,
      stock: dto.stock ?? 0,
    });
    return this.variantRepo.save(variant);
  }

  async findAll(productId?: number) {
    const where = productId ? { productId } : {};
    return this.variantRepo.find({ where });
  }

  async findOne(id: number) {
    const variant = await this.variantRepo.findOne({ where: { id } });
    if (!variant) throw new NotFoundException('Product variant not found');
    return variant;
  }

  async update(id: number, dto: UpdateProductVariantDto) {
    const variant = await this.findOne(id);
    Object.assign(variant, dto);
    return this.variantRepo.save(variant);
  }

  async remove(id: number) {
    const variant = await this.findOne(id);
    return this.variantRepo.remove(variant);
  }
}

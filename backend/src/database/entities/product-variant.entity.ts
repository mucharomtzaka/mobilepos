import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Product } from './product.entity';

@Entity('product_variants')
export class ProductVariant {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'product_id' })
  @ApiProperty()
  productId: number;

  @Column({ length: 255 })
  @ApiProperty()
  name: string;

  @Column({ name: 'price_adjustment', type: 'double', default: 0 })
  @ApiProperty()
  priceAdjustment: number;

  @Column({ default: 0 })
  @ApiProperty()
  stock: number;

  @ManyToOne(() => Product, p => p.variants, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'product_id' })
  product: Product;
}

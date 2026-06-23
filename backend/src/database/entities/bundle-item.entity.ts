import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Bundle } from './bundle.entity';
import { Product } from './product.entity';

@Entity('bundle_items')
export class BundleItem {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'bundle_id' })
  @ApiProperty()
  bundleId: number;

  @Column({ name: 'product_id' })
  @ApiProperty()
  productId: number;

  @Column({ default: 1 })
  @ApiProperty()
  qty: number;

  @ManyToOne(() => Bundle, b => b.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'bundle_id' })
  bundle: Bundle;

  @ManyToOne(() => Product)
  @JoinColumn({ name: 'product_id' })
  product: Product;
}

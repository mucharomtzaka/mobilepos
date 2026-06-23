import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Category } from './category.entity';
import { ProductVariant } from './product-variant.entity';
import { OrderItem } from './order-item.entity';
import { BundleItem } from './bundle-item.entity';
import { StockMovement } from './stock-movement.entity';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'category_id', nullable: true })
  @ApiProperty()
  categoryId: number;

  @Column({ length: 255 })
  @ApiProperty()
  name: string;

  @Column({ nullable: true, length: 100 })
  @ApiProperty()
  barcode: string;

  @Column({ type: 'double' })
  @ApiProperty()
  price: number;

  @Column({ default: 0 })
  @ApiProperty()
  stock: number;

  @Column({ length: 20, default: 'pcs' })
  @ApiProperty()
  unit: string;

  @Column({ name: 'image_path', nullable: true, length: 500 })
  @ApiProperty()
  imagePath: string;

  @Column({ name: 'is_active', default: true })
  @ApiProperty()
  isActive: boolean;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @ManyToOne(() => Category, c => c.products)
  @JoinColumn({ name: 'category_id' })
  category: Category;

  @OneToMany(() => ProductVariant, v => v.product, { cascade: true })
  variants: ProductVariant[];

  @OneToMany(() => OrderItem, oi => oi.product)
  orderItems: OrderItem[];

  @OneToMany(() => BundleItem, bi => bi.product)
  bundleItems: BundleItem[];

  @OneToMany(() => StockMovement, sm => sm.product)
  stockMovements: StockMovement[];
}

import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Order } from './order.entity';
import { Product } from './product.entity';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'order_id' })
  @ApiProperty()
  orderId: number;

  @Column({ name: 'product_id' })
  @ApiProperty()
  productId: number;

  @Column({ name: 'product_name', length: 255 })
  @ApiProperty()
  productName: string;

  @Column({ name: 'variant_name', nullable: true, length: 255 })
  @ApiProperty()
  variantName: string;

  @Column({ name: 'bundle_name', nullable: true, length: 255 })
  @ApiProperty()
  bundleName: string;

  @Column({ name: 'bundle_id', nullable: true })
  @ApiProperty()
  bundleId: number;

  @Column({ name: 'bundle_adjusted_price', type: 'double', nullable: true })
  @ApiProperty()
  bundleAdjustedPrice: number;

  @Column({ type: 'double' })
  @ApiProperty()
  price: number;

  @Column()
  @ApiProperty()
  qty: number;

  @Column({ type: 'double' })
  @ApiProperty()
  subtotal: number;

  @ManyToOne(() => Order, o => o.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;

  @ManyToOne(() => Product)
  @JoinColumn({ name: 'product_id' })
  product: Product;
}

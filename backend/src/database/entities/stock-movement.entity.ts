import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Product } from './product.entity';

@Entity('stock_movements')
export class StockMovement {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'product_id' })
  @ApiProperty()
  productId: number;

  @Column({ length: 20 })
  @ApiProperty({ enum: ['in', 'out', 'adjustment'] })
  type: string;

  @Column()
  @ApiProperty()
  qty: number;

  @Column({ nullable: true, type: 'text' })
  @ApiProperty()
  note: string;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @ManyToOne(() => Product)
  @JoinColumn({ name: 'product_id' })
  product: Product;
}

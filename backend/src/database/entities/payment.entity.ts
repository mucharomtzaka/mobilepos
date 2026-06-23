import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Order } from './order.entity';

@Entity('payments')
export class Payment {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'order_id' })
  @ApiProperty()
  orderId: number;

  @Column({ length: 20 })
  @ApiProperty({ enum: ['tunai', 'dana', 'ovo', 'gopay', 'transfer', 'qris'] })
  method: string;

  @Column({ type: 'double' })
  @ApiProperty()
  amount: number;

  @Column({ nullable: true, length: 255 })
  @ApiProperty()
  reference: string;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @ManyToOne(() => Order, o => o.payments, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' })
  order: Order;
}

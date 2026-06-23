import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, OneToMany } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from './user.entity';
import { Customer } from './customer.entity';
import { RestoTable } from './table.entity';
import { Shift } from './shift.entity';
import { OrderItem } from './order-item.entity';
import { Payment } from './payment.entity';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'order_number', unique: true, length: 50 })
  @ApiProperty()
  orderNumber: string;

  @Column({ name: 'shift_id', nullable: true })
  @ApiProperty()
  shiftId: number;

  @Column({ name: 'user_id' })
  @ApiProperty()
  userId: number;

  @Column({ name: 'customer_id', nullable: true })
  @ApiProperty()
  customerId: number;

  @Column({ name: 'table_id', nullable: true })
  @ApiProperty()
  tableId: number;

  @Column({ type: 'double' })
  @ApiProperty()
  subtotal: number;

  @Column({ name: 'discount_amount', type: 'double', default: 0 })
  @ApiProperty()
  discountAmount: number;

  @Column({ name: 'discount_type', nullable: true, length: 20 })
  @ApiProperty()
  discountType: string;

  @Column({ name: 'discount_value', type: 'double', default: 0 })
  @ApiProperty()
  discountValue: number;

  @Column({ name: 'tax_percent', type: 'double', default: 0 })
  @ApiProperty()
  taxPercent: number;

  @Column({ name: 'tax_amount', type: 'double', default: 0 })
  @ApiProperty()
  taxAmount: number;

  @Column({ type: 'double' })
  @ApiProperty()
  total: number;

  @Column({ name: 'total_paid', type: 'double', default: 0 })
  @ApiProperty()
  totalPaid: number;

  @Column({ name: 'change_amount', type: 'double', default: 0 })
  @ApiProperty()
  changeAmount: number;

  @Column({ length: 20, default: 'completed' })
  @ApiProperty({ enum: ['completed', 'draft'] })
  status: string;

  @Column({ nullable: true, type: 'text' })
  @ApiProperty()
  note: string;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;

  @ManyToOne(() => Customer)
  @JoinColumn({ name: 'customer_id' })
  customer: Customer;

  @ManyToOne(() => RestoTable)
  @JoinColumn({ name: 'table_id' })
  table: RestoTable;

  @ManyToOne(() => Shift)
  @JoinColumn({ name: 'shift_id' })
  shift: Shift;

  @OneToMany(() => OrderItem, oi => oi.order, { cascade: true })
  items: OrderItem[];

  @OneToMany(() => Payment, p => p.order, { cascade: true })
  payments: Payment[];
}

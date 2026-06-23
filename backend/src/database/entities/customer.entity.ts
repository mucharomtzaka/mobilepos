import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Order } from './order.entity';

@Entity('customers')
export class Customer {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ length: 255 })
  @ApiProperty()
  name: string;

  @Column({ nullable: true, length: 50 })
  @ApiProperty()
  phone: string;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @OneToMany(() => Order, o => o.customer)
  orders: Order[];
}

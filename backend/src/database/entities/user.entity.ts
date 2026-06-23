import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { Order } from './order.entity';
import { Shift } from './shift.entity';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ length: 255 })
  @ApiProperty()
  name: string;

  @Column({ unique: true, length: 100 })
  @ApiProperty()
  username: string;

  @Column({ length: 255 })
  password: string;

  @Column({ length: 20, default: 'kasir' })
  @ApiProperty({ enum: ['admin', 'kasir', 'merchant'] })
  role: string;

  @Column({ name: 'is_active', default: true })
  @ApiProperty()
  isActive: boolean;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @OneToMany(() => Order, o => o.user)
  orders: Order[];

  @OneToMany(() => Shift, s => s.user)
  shifts: Shift[];
}

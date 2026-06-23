import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('transactions')
export class Transaction {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ length: 20 })
  @ApiProperty({ enum: ['income', 'expense'] })
  type: string;

  @Column({ length: 100 })
  @ApiProperty()
  category: string;

  @Column({ type: 'double' })
  @ApiProperty()
  amount: number;

  @Column({ nullable: true, type: 'text' })
  @ApiProperty()
  description: string;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;
}

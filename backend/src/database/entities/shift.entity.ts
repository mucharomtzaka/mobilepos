import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { User } from './user.entity';

@Entity('shifts')
export class Shift {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ name: 'user_id' })
  @ApiProperty()
  userId: number;

  @Column({ name: 'start_time', length: 50 })
  @ApiProperty()
  startTime: string;

  @Column({ name: 'end_time', nullable: true, length: 50 })
  @ApiProperty()
  endTime: string;

  @Column({ name: 'opening_cash', type: 'double', default: 0 })
  @ApiProperty()
  openingCash: number;

  @Column({ name: 'closing_cash', type: 'double', nullable: true })
  @ApiProperty()
  closingCash: number;

  @Column({ length: 10, default: 'open' })
  @ApiProperty({ enum: ['open', 'closed'] })
  status: string;

  @ManyToOne(() => User)
  @JoinColumn({ name: 'user_id' })
  user: User;
}

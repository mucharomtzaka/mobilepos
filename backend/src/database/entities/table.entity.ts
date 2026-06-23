import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('tables')
export class RestoTable {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ length: 100 })
  @ApiProperty()
  name: string;

  @Column({ default: 4 })
  @ApiProperty()
  capacity: number;

  @Column({ nullable: true, type: 'text' })
  @ApiProperty()
  note: string;

  @Column({ name: 'is_active', default: true })
  @ApiProperty()
  isActive: boolean;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;
}

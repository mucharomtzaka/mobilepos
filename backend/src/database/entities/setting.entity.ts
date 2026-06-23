import { Entity, PrimaryColumn, Column } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';

@Entity('settings')
export class Setting {
  @PrimaryColumn({ length: 100 })
  @ApiProperty()
  key: string;

  @Column({ type: 'text', nullable: true })
  @ApiProperty()
  value: string;
}

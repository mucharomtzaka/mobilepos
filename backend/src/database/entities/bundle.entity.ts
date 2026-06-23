import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { ApiProperty } from '@nestjs/swagger';
import { BundleItem } from './bundle-item.entity';

@Entity('bundles')
export class Bundle {
  @PrimaryGeneratedColumn()
  @ApiProperty()
  id: number;

  @Column({ length: 255 })
  @ApiProperty()
  name: string;

  @Column({ type: 'double' })
  @ApiProperty()
  price: number;

  @Column({ name: 'is_active', default: true })
  @ApiProperty()
  isActive: boolean;

  @Column({ name: 'created_at', length: 50 })
  @ApiProperty()
  createdAt: string;

  @OneToMany(() => BundleItem, bi => bi.bundle, { cascade: true })
  items: BundleItem[];
}

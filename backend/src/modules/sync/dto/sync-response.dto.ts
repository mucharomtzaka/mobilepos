import { ApiProperty } from '@nestjs/swagger';

export class SyncResponseDto {
  @ApiProperty()
  serverTime: string;

  @ApiProperty()
  users: any[];

  @ApiProperty()
  categories: any[];

  @ApiProperty()
  products: any[];

  @ApiProperty()
  productVariants: any[];

  @ApiProperty()
  bundles: any[];

  @ApiProperty()
  bundleItems: any[];

  @ApiProperty()
  customers: any[];

  @ApiProperty()
  orders: any[];

  @ApiProperty()
  orderItems: any[];

  @ApiProperty()
  payments: any[];

  @ApiProperty()
  shifts: any[];

  @ApiProperty()
  stockMovements: any[];

  @ApiProperty()
  transactions: any[];

  @ApiProperty()
  tables: any[];

  @ApiProperty()
  settings: any[];

  @ApiProperty()
  counts: { [table: string]: number };
}

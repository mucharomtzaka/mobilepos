import { ApiProperty } from '@nestjs/swagger';

export class SyncPushDto {
  @ApiProperty({ required: false })
  users?: any[];

  @ApiProperty({ required: false })
  categories?: any[];

  @ApiProperty({ required: false })
  products?: any[];

  @ApiProperty({ required: false })
  productVariants?: any[];

  @ApiProperty({ required: false })
  bundles?: any[];

  @ApiProperty({ required: false })
  bundleItems?: any[];

  @ApiProperty({ required: false })
  customers?: any[];

  @ApiProperty({ required: false })
  orders?: any[];

  @ApiProperty({ required: false })
  orderItems?: any[];

  @ApiProperty({ required: false })
  payments?: any[];

  @ApiProperty({ required: false })
  shifts?: any[];

  @ApiProperty({ required: false })
  stockMovements?: any[];

  @ApiProperty({ required: false })
  transactions?: any[];

  @ApiProperty({ required: false })
  tables?: any[];

  @ApiProperty({ required: false })
  settings?: any[];
}

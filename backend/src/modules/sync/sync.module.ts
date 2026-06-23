import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SyncController } from './sync.controller';
import { SyncService } from './sync.service';
import { User } from '../../database/entities/user.entity';
import { Category } from '../../database/entities/category.entity';
import { Product } from '../../database/entities/product.entity';
import { ProductVariant } from '../../database/entities/product-variant.entity';
import { Bundle } from '../../database/entities/bundle.entity';
import { BundleItem } from '../../database/entities/bundle-item.entity';
import { Customer } from '../../database/entities/customer.entity';
import { Order } from '../../database/entities/order.entity';
import { OrderItem } from '../../database/entities/order-item.entity';
import { Payment } from '../../database/entities/payment.entity';
import { Shift } from '../../database/entities/shift.entity';
import { StockMovement } from '../../database/entities/stock-movement.entity';
import { Transaction } from '../../database/entities/transaction.entity';
import { RestoTable } from '../../database/entities/table.entity';
import { Setting } from '../../database/entities/setting.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      User,
      Category,
      Product,
      ProductVariant,
      Bundle,
      BundleItem,
      Customer,
      Order,
      OrderItem,
      Payment,
      Shift,
      StockMovement,
      Transaction,
      RestoTable,
      Setting,
    ]),
  ],
  controllers: [SyncController],
  providers: [SyncService],
})
export class SyncModule {}

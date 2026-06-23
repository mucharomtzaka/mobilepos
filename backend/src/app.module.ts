import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { DatabaseModule } from './database/database.module';
import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { CategoriesModule } from './modules/categories/categories.module';
import { ProductsModule } from './modules/products/products.module';
import { ProductVariantsModule } from './modules/product-variants/product-variants.module';
import { BundlesModule } from './modules/bundles/bundles.module';
import { CustomersModule } from './modules/customers/customers.module';
import { OrdersModule } from './modules/orders/orders.module';
import { ShiftsModule } from './modules/shifts/shifts.module';
import { StockMovementsModule } from './modules/stock-movements/stock-movements.module';
import { TransactionsModule } from './modules/transactions/transactions.module';
import { TablesModule } from './modules/tables/tables.module';
import { SettingsModule } from './modules/settings/settings.module';
import { SyncModule } from './modules/sync/sync.module';
import appConfig from './config/app.config';

@Module({
  imports: [
    ConfigModule.forRoot({ load: [appConfig] }),
    DatabaseModule,
    AuthModule,
    UsersModule,
    CategoriesModule,
    ProductsModule,
    ProductVariantsModule,
    BundlesModule,
    CustomersModule,
    OrdersModule,
    ShiftsModule,
    StockMovementsModule,
    TransactionsModule,
    TablesModule,
    SettingsModule,
    SyncModule,
  ],
})
export class AppModule {}

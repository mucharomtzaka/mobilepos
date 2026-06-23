import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, MoreThan } from 'typeorm';
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
import { SyncPushDto } from './dto/sync-push.dto';
import { SyncResponseDto } from './dto/sync-response.dto';

@Injectable()
export class SyncService {
  constructor(
    @InjectRepository(User) private userRepo: Repository<User>,
    @InjectRepository(Category) private categoryRepo: Repository<Category>,
    @InjectRepository(Product) private productRepo: Repository<Product>,
    @InjectRepository(ProductVariant) private productVariantRepo: Repository<ProductVariant>,
    @InjectRepository(Bundle) private bundleRepo: Repository<Bundle>,
    @InjectRepository(BundleItem) private bundleItemRepo: Repository<BundleItem>,
    @InjectRepository(Customer) private customerRepo: Repository<Customer>,
    @InjectRepository(Order) private orderRepo: Repository<Order>,
    @InjectRepository(OrderItem) private orderItemRepo: Repository<OrderItem>,
    @InjectRepository(Payment) private paymentRepo: Repository<Payment>,
    @InjectRepository(Shift) private shiftRepo: Repository<Shift>,
    @InjectRepository(StockMovement) private stockMovementRepo: Repository<StockMovement>,
    @InjectRepository(Transaction) private transactionRepo: Repository<Transaction>,
    @InjectRepository(RestoTable) private tableRepo: Repository<RestoTable>,
    @InjectRepository(Setting) private settingRepo: Repository<Setting>,
  ) {}

  async pull(lastSyncAt: string, tables?: string[]): Promise<SyncResponseDto> {
    const filter = tables ? new Set(tables) : null;

    const shouldSync = (table: string) => !filter || filter.has(table);

    const withCreatedAt: [string, () => Promise<any[]>][] = [
      ['users', async () => this.userRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['categories', async () => this.categoryRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['products', async () => this.productRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['bundles', async () => this.bundleRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['customers', async () => this.customerRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['orders', async () => this.orderRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['payments', async () => this.paymentRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['stockMovements', async () => this.stockMovementRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['transactions', async () => this.transactionRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
      ['tables', async () => this.tableRepo.find({ where: { createdAt: MoreThan(lastSyncAt) } })],
    ];

    const all: [string, any[]][] = await Promise.all(
      withCreatedAt.map(async ([key, fn]) => [key, shouldSync(key) ? await fn() : []]),
    );

    const noDateTables: [string, () => Promise<any[]>][] = [
      ['productVariants', () => this.productVariantRepo.find()],
      ['bundleItems', () => this.bundleItemRepo.find()],
      ['orderItems', () => this.orderItemRepo.find()],
      ['shifts', () => this.shiftRepo.find()],
      ['settings', () => this.settingRepo.find()],
    ];

    const noDateResults: [string, any[]][] = await Promise.all(
      noDateTables.map(async ([key, fn]) => [key, shouldSync(key) ? await fn() : []]),
    );

    const result: any = { serverTime: new Date().toISOString() };
    const counts: { [table: string]: number } = {};

    for (const [key, rows] of [...all, ...noDateResults]) {
      result[key] = rows;
      counts[key] = rows.length;
    }

    result.counts = counts;
    return result as SyncResponseDto;
  }

  async push(data: SyncPushDto): Promise<{ status: string; counts: { [table: string]: number } }> {
    const counts: { [table: string]: number } = {};

    const tableHandlers: [string, any[] | undefined, (rows: any[]) => Promise<void>][] = [
      ['users', data.users, async rows => { for (const r of rows) await this.userRepo.save(r); }],
      ['categories', data.categories, async rows => { for (const r of rows) await this.categoryRepo.save(r); }],
      ['products', data.products, async rows => { for (const r of rows) await this.productRepo.save(r); }],
      ['productVariants', data.productVariants, async rows => { for (const r of rows) await this.productVariantRepo.save(r); }],
      ['bundles', data.bundles, async rows => { for (const r of rows) await this.bundleRepo.save(r); }],
      ['bundleItems', data.bundleItems, async rows => { for (const r of rows) await this.bundleItemRepo.save(r); }],
      ['customers', data.customers, async rows => { for (const r of rows) await this.customerRepo.save(r); }],
      ['orders', data.orders, async rows => { for (const r of rows) await this.handleOrder(r); }],
      ['orderItems', data.orderItems, async rows => { for (const r of rows) await this.orderItemRepo.save(r); }],
      ['payments', data.payments, async rows => { for (const r of rows) await this.paymentRepo.save(r); }],
      ['shifts', data.shifts, async rows => { for (const r of rows) await this.shiftRepo.save(r); }],
      ['stockMovements', data.stockMovements, async rows => { for (const r of rows) await this.stockMovementRepo.save(r); }],
      ['transactions', data.transactions, async rows => { for (const r of rows) await this.transactionRepo.save(r); }],
      ['tables', data.tables, async rows => { for (const r of rows) await this.tableRepo.save(r); }],
      ['settings', data.settings, async rows => { for (const r of rows) await this.settingRepo.save(r); }],
    ];

    for (const [key, rows, handler] of tableHandlers) {
      if (!rows || rows.length === 0) continue;
      await handler(rows);
      counts[key] = rows.length;
    }

    return { status: 'ok', counts };
  }

  private async handleOrder(orderData: any) {
    const { items, payments, ...orderFields } = orderData;
    const saved = await this.orderRepo.save(orderFields);

    if (items && items.length > 0) {
      await this.orderItemRepo.delete({ orderId: saved.id });
      const newItems = items.map((i: any) => ({ ...i, orderId: saved.id }));
      await this.orderItemRepo.save(newItems);
    }

    if (payments && payments.length > 0) {
      await this.paymentRepo.delete({ orderId: saved.id });
      const newPayments = payments.map((p: any) => ({ ...p, orderId: saved.id }));
      await this.paymentRepo.save(newPayments);
    }
  }
}

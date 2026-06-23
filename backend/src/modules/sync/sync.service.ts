import { Injectable } from '@nestjs/common';
import { InjectRepository, InjectDataSource } from '@nestjs/typeorm';
import { Repository, MoreThan, DataSource } from 'typeorm';
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
    @InjectDataSource() private dataSource: DataSource,
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

    await this.dataSource.transaction(async (em) => {
      await em.query('SET FOREIGN_KEY_CHECKS = 0');

      const tableMap: [string, any[] | undefined, any][] = [
        ['users', data.users, User],
        ['categories', data.categories, Category],
        ['products', data.products, Product],
        ['productVariants', data.productVariants, ProductVariant],
        ['bundles', data.bundles, Bundle],
        ['bundleItems', data.bundleItems, BundleItem],
        ['customers', data.customers, Customer],
        ['orders', data.orders, Order],
        ['orderItems', data.orderItems, OrderItem],
        ['payments', data.payments, Payment],
        ['shifts', data.shifts, Shift],
        ['stockMovements', data.stockMovements, StockMovement],
        ['transactions', data.transactions, Transaction],
        ['tables', data.tables, RestoTable],
        ['settings', data.settings, Setting],
      ];

      for (const [key, rows, entity] of tableMap) {
        if (!rows || rows.length === 0) continue;
        try {
          const repo = em.getRepository(entity);
          for (let r of rows) {
            if (key === 'users') {
              const existing = await repo.findOne({ where: { id: r.id } });
              if (existing && !r.password) r.password = existing.password;
            }
            await repo.save(r);
          }
          counts[key] = rows.length;
        } catch (e: any) {
          console.error(`Sync push error on ${key}:`, e.message);
        }
      }

      await em.query('SET FOREIGN_KEY_CHECKS = 1');
    });

    return { status: 'ok', counts };
  }
}

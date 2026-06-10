import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  DatabaseHelper._();

  Future<Database> get db async => _db ??= await _initDb();

  String? _dbPath;

  Future<String> get dbPath async {
    if (_dbPath != null) return _dbPath!;
    _dbPath = join(await getDatabasesPath(), 'mobilepos.db');
    return _dbPath!;
  }

  Future<void> close() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
  }

  Future<Database> _initDb() async {
    _dbPath = join(await getDatabasesPath(), 'mobilepos.db');
    return openDatabase(_dbPath!, version: 14, onCreate: _onCreate, onUpgrade: _onUpgrade);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE product_variants (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          product_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          price_adjustment REAL NOT NULL DEFAULT 0,
          stock INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('''
        ALTER TABLE order_items ADD COLUMN variant_name TEXT
      ''');
    }
    if (oldVersion < 3) {
      await db.execute('''
        ALTER TABLE orders ADD COLUMN tax_percent REAL NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE orders ADD COLUMN tax_amount REAL NOT NULL DEFAULT 0
      ''');
    }
    if (oldVersion < 4) {
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN variant_name TEXT
        ''');
      } catch (_) {
        // column may already exist
      }
    }
    if (oldVersion < 5) {
      try {
        await db.execute('''
          ALTER TABLE orders ADD COLUMN total_paid REAL NOT NULL DEFAULT 0
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          ALTER TABLE orders ADD COLUMN change_amount REAL NOT NULL DEFAULT 0
        ''');
      } catch (_) {}
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          phone TEXT,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute('''
          ALTER TABLE orders ADD COLUMN customer_id INTEGER
        ''');
      } catch (_) {}
    }
    // Version 7: Add settings table
    if (oldVersion < 7) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS settings (
          key TEXT PRIMARY KEY,
          value TEXT
        )
      ''');
    }
    // Version 8: Add transactions table
    if (oldVersion < 8) {
      await db.execute('''
        CREATE TABLE transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    // Version 9: Add tables table
    if (oldVersion < 9) {
      await db.execute('''
        CREATE TABLE tables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          capacity INTEGER NOT NULL DEFAULT 4,
          note TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      try {
        await db.execute('''
          ALTER TABLE orders ADD COLUMN table_id INTEGER
        ''');
      } catch (_) {}
    }
    // Version 10: Add bundles table
    if (oldVersion < 10) {
      await db.execute('''
        CREATE TABLE bundles (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          price REAL NOT NULL,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
      await db.execute('''
        CREATE TABLE bundle_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          bundle_id INTEGER NOT NULL,
          product_id INTEGER NOT NULL,
          qty INTEGER NOT NULL DEFAULT 1,
          FOREIGN KEY (bundle_id) REFERENCES bundles(id) ON DELETE CASCADE,
          FOREIGN KEY (product_id) REFERENCES products(id)
        )
      ''');
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN bundle_name TEXT
        ''');
      } catch (_) {}
    }
    // Version 11: Add tables table
    if (oldVersion < 11) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS tables (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          capacity INTEGER NOT NULL DEFAULT 4,
          note TEXT,
          is_active INTEGER NOT NULL DEFAULT 1,
          created_at TEXT NOT NULL
        )
      ''');
    }
    // Version 12: Add bundle_id & bundle_adjusted_price to order_items
    if (oldVersion < 12) {
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN bundle_id INTEGER
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN bundle_adjusted_price REAL
        ''');
      } catch (_) {}
    }
    // Version 13: Ensure table_id column exists on orders
    if (oldVersion < 13) {
      try {
        await db.execute('''
          ALTER TABLE orders ADD COLUMN table_id INTEGER
        ''');
      } catch (_) {}
    }
    // Version 14: Ensure bundle columns exist on order_items
    if (oldVersion < 14) {
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN bundle_name TEXT
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN bundle_id INTEGER
        ''');
      } catch (_) {}
      try {
        await db.execute('''
          ALTER TABLE order_items ADD COLUMN bundle_adjusted_price REAL
        ''');
      } catch (_) {}
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        username TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'kasir',
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        name TEXT NOT NULL,
        barcode TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL DEFAULT 0,
        unit TEXT NOT NULL DEFAULT 'pcs',
        image_path TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE shifts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        start_time TEXT NOT NULL,
        end_time TEXT,
        opening_cash REAL NOT NULL DEFAULT 0,
        closing_cash REAL,
        status TEXT NOT NULL DEFAULT 'open',
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_number TEXT UNIQUE NOT NULL,
        shift_id INTEGER,
        user_id INTEGER NOT NULL,
        customer_id INTEGER,
        table_id INTEGER,
        subtotal REAL NOT NULL,
        discount_amount REAL NOT NULL DEFAULT 0,
        discount_type TEXT,
        discount_value REAL NOT NULL DEFAULT 0,
        tax_percent REAL NOT NULL DEFAULT 0,
        tax_amount REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL,
        total_paid REAL NOT NULL DEFAULT 0,
        change_amount REAL NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'completed',
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (shift_id) REFERENCES shifts(id),
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        variant_name TEXT,
        bundle_name TEXT,
        bundle_id INTEGER,
        bundle_adjusted_price REAL,
        price REAL NOT NULL,
        qty INTEGER NOT NULL,
        subtotal REAL NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id),
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        order_id INTEGER NOT NULL,
        method TEXT NOT NULL,
        amount REAL NOT NULL,
        reference TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        qty INTEGER NOT NULL,
        note TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE product_variants (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        price_adjustment REAL NOT NULL DEFAULT 0,
        stock INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE bundles (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE bundle_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        bundle_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        qty INTEGER NOT NULL DEFAULT 1,
        FOREIGN KEY (bundle_id) REFERENCES bundles(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE tables (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        capacity INTEGER NOT NULL DEFAULT 4,
        note TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    // Seed admin user
    await db.insert('users', {
      'name': 'Admin',
      'username': 'admin',
      'password': 'admin123',
      'role': 'admin',
      'is_active': 1,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}

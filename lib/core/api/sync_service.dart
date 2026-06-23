import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../database/settings_dao.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _api = ApiService.instance;
  final _settings = SettingsDao();
  final _dbHelper = DatabaseHelper.instance;

  String? _lastError;
  String? get lastError => _lastError;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  Future<DateTime?> get lastSyncAt async {
    final v = await _settings.get('last_sync_at');
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<bool> login(String username, String password) async {
    try {
      final res = await _api.post('/api/auth/login', {
        'username': username,
        'password': password,
      }, auth: false);
      final token = res['accessToken'] as String?;
      if (token == null) return false;
      await _api.setToken(token);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> register(String name, String username, String password, {String role = 'kasir'}) async {
    try {
      final res = await _api.post('/api/auth/register', {
        'name': name,
        'username': username,
        'password': password,
        'role': role,
      }, auth: false);
      final token = res['accessToken'] as String?;
      if (token == null) return false;
      await _api.setToken(token);
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    }
  }

  Future<bool> syncAll() async {
    if (_syncing) return false;
    _syncing = true;
    _lastError = null;
    try {
      await _push();
      await _pull();
      await _settings.set('last_sync_at', DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _syncing = false;
    }
  }

  Future<void> _push() async {
    final db = await _dbHelper.db;

    final tables = <String, String>{
      'users': 'users',
      'categories': 'categories',
      'products': 'products',
      'productVariants': 'product_variants',
      'bundles': 'bundles',
      'bundleItems': 'bundle_items',
      'customers': 'customers',
      'orders': 'orders',
      'orderItems': 'order_items',
      'payments': 'payments',
      'shifts': 'shifts',
      'stockMovements': 'stock_movements',
      'transactions': 'transactions',
      'tables': 'tables',
      'settings': 'settings',
    };

    final payload = <String, dynamic>{};
    for (final entry in tables.entries) {
      final rows = await db.query(entry.value);
      if (rows.isEmpty) continue;
      payload[entry.key] = rows.map(_snakeToCamel).toList();
    }

    if (payload.isEmpty) return;
    await _api.post('/api/sync/push', payload);
  }

  Future<void> _pull() async {
    final db = await _dbHelper.db;
    final lastSync = await _settings.get('last_sync_at') ?? '';

    final tables = <String, String>{
      'users': 'users',
      'categories': 'categories',
      'products': 'products',
      'productVariants': 'product_variants',
      'bundles': 'bundles',
      'bundleItems': 'bundle_items',
      'customers': 'customers',
      'orders': 'orders',
      'orderItems': 'order_items',
      'payments': 'payments',
      'shifts': 'shifts',
      'stockMovements': 'stock_movements',
      'transactions': 'transactions',
      'tables': 'tables',
      'settings': 'settings',
    };

    final res = await _api.post('/api/sync/pull', {
      'lastSyncAt': lastSync,
    });

    await db.transaction((txn) async {
      for (final entry in tables.entries) {
        final apiKey = entry.key;
        final tableName = entry.value;
        final rows = res[apiKey];
        if (rows is! List || rows.isEmpty) continue;
        for (final row in rows) {
          final map = _camelToSnake(row as Map<String, dynamic>);
          _stripRelations(map);
          await txn.insert(tableName, map,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
  }

  void _stripRelations(Map<String, dynamic> map) {
    map.remove('user');
    map.remove('category');
    map.remove('product');
    map.remove('customer');
    map.remove('table');
    map.remove('shift');
    map.remove('bundle');
    map.remove('order');
    map.remove('variants');
    map.remove('items');
    map.remove('payments');
    map.remove('orders');
    map.remove('bundleItems');
    map.remove('stockMovements');
    map.remove('shifts');
    map.remove('products');
    map.remove('orderItems');
  }

  Map<String, dynamic> _snakeToCamel(Map<String, dynamic> m) {
    final result = <String, dynamic>{};
    for (final entry in m.entries) {
      result[_toCamelCase(entry.key)] = entry.value;
    }
    result.remove('id');
    return result;
  }

  Map<String, dynamic> _camelToSnake(Map<String, dynamic> m) {
    final result = <String, dynamic>{};
    for (final entry in m.entries) {
      result[_toSnakeCase(entry.key)] = entry.value;
    }
    return result;
  }

  String _toCamelCase(String s) {
    final parts = s.split('_');
    if (parts.length == 1) return s;
    return parts[0] + parts.skip(1).map((p) => p[0].toUpperCase() + p.substring(1)).join();
  }

  String _toSnakeCase(String s) {
    return s.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => '_${m.group(0)!.toLowerCase()}',
    );
  }
}

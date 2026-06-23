import 'package:flutter/foundation.dart';
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

  static const _keyEnabled = 'sync_enabled';
  static const _keyLog = 'sync_log';

  String? _lastError;
  String? get lastError => _lastError;

  bool _syncing = false;
  bool get isSyncing => _syncing;

  Future<bool> get isEnabled async {
    final v = await _settings.get(_keyEnabled);
    return v == 'true';
  }

  Future<void> setEnabled(bool v) async {
    await _settings.set(_keyEnabled, v.toString());
  }

  Future<DateTime?> get lastSyncAt async {
    final v = await _settings.get('last_sync_at');
    if (v == null) return null;
    return DateTime.tryParse(v);
  }

  Future<String?> get lastLog async => _settings.get(_keyLog);

  Future<void> _log(String msg) async {
    final ts = DateTime.now().toIso8601String();
    debugPrint('[SYNC] $msg');
    await _settings.set(_keyLog, '[$ts] $msg');
  }

  Future<bool> syncAll() async {
    if (_syncing) {
      await _log('Sync skipped: already in progress');
      return false;
    }
    _syncing = true;
    _lastError = null;
    await _log('Sync started');
    try {
      await _push();
      await _pull();
      final now = DateTime.now().toIso8601String();
      await _settings.set('last_sync_at', now);
      await _log('Sync completed at $now');
      return true;
    } catch (e) {
      _lastError = e.toString();
      await _log('Sync error: $e');
      return false;
    } finally {
      _syncing = false;
    }
  }

  Future<void> _push() async {
    final db = await _dbHelper.db;
    final tables = <String, String>{
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
    };
    final payload = <String, dynamic>{};
    final counts = <String, int>{};
    for (final e in tables.entries) {
      final rows = await db.query(e.value);
      if (rows.isEmpty) continue;
      payload[e.key] = rows.map(_snakeToCamel).toList();
      counts[e.key] = rows.length;
    }
    if (payload.isEmpty) {
      await _log('Push: no data');
      return;
    }
    await _log('Push: $counts');
    await _api.post('/api/sync/push', payload);
    await _log('Push OK');
  }

  Future<void> _pull() async {
    final db = await _dbHelper.db;
    final lastSync = await _settings.get('last_sync_at') ?? '';
    final tables = <String, String>{
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
    };
    await _log('Pull: lastSyncAt=$lastSync');
    final res = await _api.post('/api/sync/pull', {'lastSyncAt': lastSync});
    final counts = <String, int>{};
    await db.transaction((txn) async {
      for (final e in tables.entries) {
        final rows = res[e.key];
        if (rows is! List || rows.isEmpty) continue;
        counts[e.key] = rows.length;
        for (final row in rows) {
          final map = _camelToSnake(row as Map<String, dynamic>);
          _stripRelations(map);
          await txn.insert(e.value, map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    });
    await _log('Pull: $counts');
    await _log('Pull OK');
  }

  void _stripRelations(Map<String, dynamic> m) {
    for (final k in ['user','category','product','customer','table','shift','bundle','order',
        'variants','items','payments','orders','bundleItems','stockMovements','shifts','products','orderItems']) {
      m.remove(k);
    }
  }

  Map<String, dynamic> _snakeToCamel(Map<String, dynamic> m) {
    final r = <String, dynamic>{};
    for (final e in m.entries) { r[_toCamel(e.key)] = e.value; }
    return r;
  }

  Map<String, dynamic> _camelToSnake(Map<String, dynamic> m) {
    final r = <String, dynamic>{};
    for (final e in m.entries) { r[_toSnake(e.key)] = e.value; }
    return r;
  }

  String _toCamel(String s) {
    final p = s.split('_');
    if (p.length == 1) return s;
    return p[0] + p.skip(1).map((e) => e[0].toUpperCase() + e.substring(1)).join();
  }

  String _toSnake(String s) =>
      s.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');
}

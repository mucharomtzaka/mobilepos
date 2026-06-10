import '../database/database_helper.dart';
import '../models/bundle.dart';
import '../models/bundle_item.dart';
import 'product_dao.dart';

class BundleDao {
  final _db = DatabaseHelper.instance;
  final _productDao = ProductDao();

  Future<List<Bundle>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('bundles',
        where: 'is_active = 1', orderBy: 'name ASC');
    return rows.map(Bundle.fromMap).toList();
  }

  Future<List<Bundle>> getAllPaginated({
    String? search,
    required int limit,
    required int offset,
  }) async {
    final db = await _db.db;
    final wheres = <String>['is_active = 1'];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      wheres.add('name LIKE ?');
      args.add('%$search%');
    }
    final where = wheres.join(' AND ');
    final rows = await db.query(
      'bundles',
      where: where,
      whereArgs: args,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Bundle.fromMap).toList();
  }

  Future<int> getCount({String? search}) async {
    final db = await _db.db;
    final wheres = <String>['is_active = 1'];
    final args = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      wheres.add('name LIKE ?');
      args.add('%$search%');
    }
    final where = wheres.join(' AND ');
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM bundles WHERE $where',
      args,
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<Bundle?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.query('bundles',
        where: 'id = ? AND is_active = 1', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Bundle.fromMap(rows.first);
  }

  Future<int> insert(Bundle b) async {
    final db = await _db.db;
    return db.insert('bundles', b.toMap());
  }

  Future<int> update(Bundle b) async {
    final db = await _db.db;
    return db.update('bundles', b.toMap(), where: 'id = ?', whereArgs: [b.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.db;
    return db.update('bundles', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<List<BundleItem>> getItems(int bundleId) async {
    final db = await _db.db;
    final rows = await db.query('bundle_items',
        where: 'bundle_id = ?', whereArgs: [bundleId]);
    final items = rows.map(BundleItem.fromMap).toList();
    for (var i = 0; i < items.length; i++) {
      final product = await _productDao.getById(items[i].productId);
      items[i] = items[i].copyWith(product: product);
    }
    return items;
  }

  Future<void> insertItem(BundleItem item) async {
    final db = await _db.db;
    await db.insert('bundle_items', item.toMap());
  }

  Future<void> deleteItemsByBundle(int bundleId) async {
    final db = await _db.db;
    await db.delete('bundle_items',
        where: 'bundle_id = ?', whereArgs: [bundleId]);
  }
}

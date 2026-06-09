import '../database/database_helper.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_variant.dart';

class CategoryDao {
  final _db = DatabaseHelper.instance;

  Future<List<Category>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('categories', orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<List<Category>> getAllPaginated({
    required int limit,
    required int offset,
    String? search,
  }) async {
    final db = await _db.db;
    String? where;
    List<dynamic>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ?';
      whereArgs = ['%$search%'];
    }
    final rows = await db.query(
      'categories',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> getCount({String? search}) async {
    final db = await _db.db;
    String? where;
    List<dynamic>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ?';
      whereArgs = ['%$search%'];
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM categories${where != null ? ' WHERE $where' : ''}',
      whereArgs ?? [],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> insert(Category c) async {
    final db = await _db.db;
    return db.insert('categories', c.toMap());
  }

  Future<int> update(Category c) async {
    final db = await _db.db;
    return db.update('categories', c.toMap(), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.db;
    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}

class ProductDao {
  final _db = DatabaseHelper.instance;

  Future<List<ProductVariant>> _getVariants(int productId) async {
    final db = await _db.db;
    final rows = await db.query('product_variants',
        where: 'product_id = ?', whereArgs: [productId], orderBy: 'name ASC');
    return rows.map(ProductVariant.fromMap).toList();
  }

  Future<Product> _loadVariants(Product p) async {
    final variants = await _getVariants(p.id!);
    return p.copyWith(variants: variants);
  }

  Future<List<Product>> getAll({int? categoryId, String? search}) async {
    final db = await _db.db;
    final wheres = <String>['p.is_active = 1'];
    final args = <dynamic>[];
    if (categoryId != null) {
      wheres.add('p.category_id = ?');
      args.add(categoryId);
    }
    if (search != null && search.isNotEmpty) {
      wheres.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    final where = wheres.join(' AND ');
    final rows = await db.rawQuery('''
      SELECT p.id, p.category_id, p.name, p.barcode, p.price, p.stock, p.unit, p.image_path, p.is_active, p.created_at, c.name as category_name
      FROM products p LEFT JOIN categories c ON p.category_id = c.id
      WHERE $where ORDER BY p.name ASC
    ''', args);
    // Remove duplicates by id
    final uniqueRows = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row['id'] as int;
      uniqueRows[id] = row;
    }
    final uniqueRowsList = uniqueRows.values.toList();
    final products = uniqueRowsList.map((m) => Product.fromMap(m)).toList();
    for (var i = 0; i < products.length; i++) {
      products[i] = await _loadVariants(products[i]);
    }
    return products;
  }

  Future<List<Product>> getAllPaginated({
    int? categoryId,
    String? search,
    required int limit,
    required int offset,
  }) async {
    final db = await _db.db;
    final wheres = <String>['p.is_active = 1'];
    final args = <dynamic>[];
    if (categoryId != null) {
      wheres.add('p.category_id = ?');
      args.add(categoryId);
    }
    if (search != null && search.isNotEmpty) {
      wheres.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    final where = wheres.join(' AND ');
    final rows = await db.rawQuery('''
      SELECT p.id, p.category_id, p.name, p.barcode, p.price, p.stock, p.unit, p.image_path, p.is_active, p.created_at, c.name as category_name
      FROM products p LEFT JOIN categories c ON p.category_id = c.id
      WHERE $where ORDER BY p.name ASC LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);
    final uniqueRows = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final id = row['id'] as int;
      uniqueRows[id] = row;
    }
    final uniqueRowsList = uniqueRows.values.toList();
    final products = uniqueRowsList.map((m) => Product.fromMap(m)).toList();
    for (var i = 0; i < products.length; i++) {
      products[i] = await _loadVariants(products[i]);
    }
    return products;
  }

  Future<int> getCount({int? categoryId, String? search}) async {
    final db = await _db.db;
    final wheres = <String>['p.is_active = 1'];
    final args = <dynamic>[];
    if (categoryId != null) {
      wheres.add('p.category_id = ?');
      args.add(categoryId);
    }
    if (search != null && search.isNotEmpty) {
      wheres.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      args.addAll(['%$search%', '%$search%']);
    }
    final where = wheres.join(' AND ');
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE $where',
      args,
    );
    return (result.first['cnt'] as int);
  }

  Future<Product?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.id = ? AND p.is_active = 1
    ''', [id]);
    if (rows.isEmpty) return null;
    return _loadVariants(Product.fromMap(rows.first));
  }

  Future<Product?> getByBarcode(String barcode) async {
    final db = await _db.db;
    final rows = await db.rawQuery('''
      SELECT p.*, c.name as category_name
      FROM products p LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.barcode = ? AND p.is_active = 1
    ''', [barcode]);
    if (rows.isEmpty) return null;
    final p = Product.fromMap(rows.first);
    return _loadVariants(p);
  }

  Future<int> insert(Product p) async {
    final db = await _db.db;
    return db.insert('products', p.toMap());
  }

  Future<int> update(Product p) async {
    final db = await _db.db;
    return db.update('products', p.toMap(), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> updateStock(int productId, int newStock) async {
    final db = await _db.db;
    return db.update('products', {'stock': newStock},
        where: 'id = ?', whereArgs: [productId]);
  }

  Future<int> delete(int id) async {
    final db = await _db.db;
    return db.update('products', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  // Variant operations
  Future<int> insertVariant(ProductVariant v) async {
    final db = await _db.db;
    return db.insert('product_variants', v.toMap());
  }

  Future<int> updateVariant(ProductVariant v) async {
    final db = await _db.db;
    return db.update('product_variants', v.toMap(),
        where: 'id = ?', whereArgs: [v.id]);
  }

  Future<int> deleteVariant(int id) async {
    final db = await _db.db;
    return db.delete('product_variants', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteVariantsByProduct(int productId) async {
    final db = await _db.db;
    await db.delete('product_variants',
        where: 'product_id = ?', whereArgs: [productId]);
  }
}

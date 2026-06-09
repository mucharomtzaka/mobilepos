import '../database/database_helper.dart';
import '../models/stock_movement.dart';

class StockDao {
  final _db = DatabaseHelper.instance;

  Future<int> addMovement(StockMovement m) async {
    final db = await _db.db;
    final id = await db.insert('stock_movements', m.toMap());
    // Update product stock
    final delta = m.type == 'out' ? -m.qty : m.qty;
    await db.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [delta, m.productId]);
    return id;
  }

  Future<List<StockMovement>> getByProduct(int productId) async {
    final db = await _db.db;
    final rows = await db.rawQuery('''
      SELECT sm.*, p.name as product_name FROM stock_movements sm
      JOIN products p ON sm.product_id = p.id
      WHERE sm.product_id = ? ORDER BY sm.created_at DESC
    ''', [productId]);
    return rows.map(StockMovement.fromMap).toList();
  }

  Future<List<StockMovement>> getLowStock({int threshold = 5}) async {
    final db = await _db.db;
    final rows = await db.rawQuery('''
      SELECT p.id as product_id, p.name as product_name, p.stock,
             NULL as id, 'info' as type, 0 as qty, NULL as note,
             p.created_at
      FROM products p WHERE p.stock <= ? AND p.is_active = 1
      ORDER BY p.stock ASC
    ''', [threshold]);
    return rows.map(StockMovement.fromMap).toList();
  }
}

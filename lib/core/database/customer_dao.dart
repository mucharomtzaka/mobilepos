import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerDao {
  final _db = DatabaseHelper.instance;

  Future<List<Customer>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('customers', orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<List<Customer>> getAllPaginated({
    int limit = 20,
    int offset = 0,
    String? search,
  }) async {
    final db = await _db.db;
    String? where;
    List<dynamic>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR phone LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }
    final rows = await db.query(
      'customers',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> getCount({String? search}) async {
    final db = await _db.db;
    String? where;
    List<dynamic>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR phone LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM customers${where != null ? ' WHERE $where' : ''}',
      whereArgs ?? [],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<Customer?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<int> insert(Customer c) async {
    final db = await _db.db;
    return db.insert('customers', c.toMap());
  }

  Future<int> update(Customer c) async {
    final db = await _db.db;
    return db.update('customers', c.toMap(),
        where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.db;
    return db.delete('customers', where: 'id = ?', whereArgs: [id]);
  }
}

import '../database/database_helper.dart';
import '../models/transaction.dart';

class TransactionDao {
  final _db = DatabaseHelper.instance;

  Future<List<Transaction>> getAll({String? type}) async {
    final db = await _db.db;
    final rows = type != null
        ? await db.query('transactions',
            where: 'type = ?', whereArgs: [type], orderBy: 'created_at DESC')
        : await db.query('transactions', orderBy: 'created_at DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  Future<List<Transaction>> getAllPaginated({
    String? type,
    String? startDate,
    String? endDate,
    required int limit,
    required int offset,
  }) async {
    final db = await _db.db;
    final where = <String>[];
    final args = <dynamic>[];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (startDate != null) {
      where.add('created_at >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('created_at <= ?');
      args.add(endDate);
    }
    final rows = await db.query(
      'transactions',
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );
    return rows.map(Transaction.fromMap).toList();
  }

  Future<double> getTotal({String? type, String? startDate, String? endDate}) async {
    final db = await _db.db;
    final where = <String>[];
    final args = <dynamic>[];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    if (startDate != null) {
      where.add('created_at >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('created_at <= ?');
      args.add(endDate);
    }
    final sql = 'SELECT COALESCE(SUM(amount), 0) as total FROM transactions'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}';
    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Transaction>> getByDateRange(
      String startDate, String endDate,
      {String? type}) async {
    final db = await _db.db;
    final where = <String>['created_at >= ?', 'created_at <= ?'];
    final args = <String>[startDate, endDate];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    final rows = await db.query('transactions',
        where: where.join(' AND '),
        whereArgs: args,
        orderBy: 'created_at DESC');
    return rows.map(Transaction.fromMap).toList();
  }

  Future<double> getTotalByDateRange(String startDate, String endDate,
      {String? type}) async {
    final db = await _db.db;
    final where = <String>['created_at >= ?', 'created_at <= ?'];
    final args = <String>[startDate, endDate];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE ${where.join(' AND ')}',
      args,
    );
    return (result.first['total'] as num).toDouble();
  }

  Future<List<Map<String, dynamic>>> getCategorySummary(
      String startDate, String endDate,
      {String? type}) async {
    final db = await _db.db;
    final where = <String>['created_at >= ?', 'created_at <= ?'];
    final args = <String>[startDate, endDate];
    if (type != null) {
      where.add('type = ?');
      args.add(type);
    }
    return db.rawQuery(
      'SELECT category, SUM(amount) as total, COUNT(*) as count '
      'FROM transactions WHERE ${where.join(' AND ')} '
      'GROUP BY category ORDER BY total DESC',
      args,
    );
  }

  Future<int> insert(Transaction t) async {
    final db = await _db.db;
    return db.insert('transactions', t.toMap());
  }

  Future<int> update(Transaction t) async {
    final db = await _db.db;
    return db.update('transactions', t.toMap(),
        where: 'id = ?', whereArgs: [t.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.db;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}

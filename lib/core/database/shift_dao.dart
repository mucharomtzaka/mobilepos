import '../database/database_helper.dart';
import '../models/shift.dart';

class ShiftDao {
  final _db = DatabaseHelper.instance;

  Future<Shift?> getOpenShift(int userId) async {
    final db = await _db.db;
    final rows = await db.rawQuery('''
      SELECT s.*, u.name as user_name FROM shifts s
      JOIN users u ON s.user_id = u.id
      WHERE s.user_id = ? AND s.status = 'open'
      ORDER BY s.start_time DESC LIMIT 1
    ''', [userId]);
    return rows.isEmpty ? null : Shift.fromMap(rows.first);
  }

  Future<int> openShift(Shift shift) async {
    final db = await _db.db;
    return db.insert('shifts', shift.toMap());
  }

  Future<int> closeShift(int shiftId, double closingCash) async {
    final db = await _db.db;
    return db.update(
      'shifts',
      {
        'status': 'closed',
        'end_time': DateTime.now().toIso8601String(),
        'closing_cash': closingCash,
      },
      where: 'id = ?',
      whereArgs: [shiftId],
    );
  }

  Future<List<Shift>> getHistory({int? userId}) async {
    final db = await _db.db;
    final where = userId != null ? 'WHERE s.user_id = $userId' : '';
    final rows = await db.rawQuery('''
      SELECT s.*, u.name as user_name FROM shifts s
      JOIN users u ON s.user_id = u.id
      $where ORDER BY s.start_time DESC
    ''');
    return rows.map(Shift.fromMap).toList();
  }

  Future<double> getTotalOpeningCash({String? startDate, String? endDate}) async {
    final db = await _db.db;
    final where = <String>[];
    final args = <dynamic>[];
    if (startDate != null) {
      where.add('start_time >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('start_time <= ?');
      args.add(endDate);
    }
    final sql = 'SELECT COALESCE(SUM(opening_cash), 0) as total FROM shifts'
        '${where.isEmpty ? '' : ' WHERE ${where.join(' AND ')}'}';
    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num).toDouble();
  }

  Future<double> getTotalClosingCash({String? startDate, String? endDate}) async {
    final db = await _db.db;
    final where = <String>["status = 'closed'"];
    final args = <dynamic>[];
    if (startDate != null) {
      where.add('start_time >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('start_time <= ?');
      args.add(endDate);
    }
    final sql = 'SELECT COALESCE(SUM(closing_cash), 0) as total FROM shifts'
        ' WHERE ${where.join(' AND ')}';
    final result = await db.rawQuery(sql, args);
    return (result.first['total'] as num).toDouble();
  }

  Future<bool> hasOpenShift({String? startDate, String? endDate}) async {
    final db = await _db.db;
    final where = <String>["status = 'open'"];
    final args = <dynamic>[];
    if (startDate != null) {
      where.add('start_time >= ?');
      args.add(startDate);
    }
    if (endDate != null) {
      where.add('start_time <= ?');
      args.add(endDate);
    }
    final sql = 'SELECT COUNT(*) as cnt FROM shifts WHERE ${where.join(' AND ')}';
    final result = await db.rawQuery(sql, args);
    return (result.first['cnt'] as int) > 0;
  }
}

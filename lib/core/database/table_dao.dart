import 'package:sqflite/sqflite.dart';
import '../models/table.dart';
import 'database_helper.dart';

class TableDao {
  final _db = DatabaseHelper.instance;

  Future<int> insert(RestoTable table) async {
    final db = await _db.db;
    return db.insert('tables', table.toMap());
  }

  Future<void> update(RestoTable table) async {
    final db = await _db.db;
    await db.update(
      'tables',
      table.toMap(),
      where: 'id = ?',
      whereArgs: [table.id],
    );
  }

  Future<void> delete(int id) async {
    final db = await _db.db;
    await db.delete('tables', where: 'id = ?', whereArgs: [id]);
  }

  Future<RestoTable?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.query('tables', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return RestoTable.fromMap(rows.first);
  }

  Future<List<RestoTable>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('tables', orderBy: 'name ASC');
    return rows.map(RestoTable.fromMap).toList();
  }

  Future<List<RestoTable>> getActive() async {
    final db = await _db.db;
    final rows = await db.query(
      'tables',
      where: 'is_active = 1',
      orderBy: 'name ASC',
    );
    return rows.map(RestoTable.fromMap).toList();
  }
}
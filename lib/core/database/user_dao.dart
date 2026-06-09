import '../database/database_helper.dart';
import '../models/user.dart';

class UserDao {
  final _db = DatabaseHelper.instance;

  Future<User?> login(String username, String password) async {
    final db = await _db.db;
    final rows = await db.query('users',
        where: 'username = ? AND password = ? AND is_active = 1',
        whereArgs: [username, password]);
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<bool> isUsernameTaken(String username) async {
    final db = await _db.db;
    final rows = await db.query('users',
        where: 'username = ?', whereArgs: [username], limit: 1);
    return rows.isNotEmpty;
  }

  Future<User?> getById(int id) async {
    final db = await _db.db;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : User.fromMap(rows.first);
  }

  Future<List<User>> getAll() async {
    final db = await _db.db;
    final rows = await db.query('users', orderBy: 'name ASC');
    return rows.map(User.fromMap).toList();
  }

  Future<List<User>> getAllPaginated({
    int limit = 20,
    int offset = 0,
    String? search,
  }) async {
    final db = await _db.db;
    String? where;
    List<dynamic>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR username LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }
    final rows = await db.query(
      'users',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );
    return rows.map(User.fromMap).toList();
  }

  Future<int> getCount({String? search}) async {
    final db = await _db.db;
    String? where;
    List<dynamic>? whereArgs;
    if (search != null && search.isNotEmpty) {
      where = 'name LIKE ? OR username LIKE ?';
      whereArgs = ['%$search%', '%$search%'];
    }
    final result = await db.rawQuery(
      'SELECT COUNT(*) as cnt FROM users${where != null ? ' WHERE $where' : ''}',
      whereArgs ?? [],
    );
    return (result.first['cnt'] as int?) ?? 0;
  }

  Future<int> insert(User user) async {
    final db = await _db.db;
    return db.insert('users', user.toMap());
  }

  Future<int> update(User user) async {
    final db = await _db.db;
    return db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.db;
    return db.update('users', {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> hardDelete(int id) async {
    final db = await _db.db;
    return db.delete('users', where: 'id = ?', whereArgs: [id]);
  }
}

import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SettingsDao {
  static const _table = 'settings';
  static const _keyThemeMode = 'theme_mode';
  static const _keyReduceStock = 'reduce_stock';

  Future<ThemeMode> getThemeMode() async {
    final db = await DatabaseHelper.instance.db;
    final result = await db.query(_table, where: 'key = ?', whereArgs: [_keyThemeMode]);
    if (result.isEmpty) return ThemeMode.system;
    final value = result.first['value'] as String?;
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    final db = await DatabaseHelper.instance.db;
    final value = mode.name;
    await db.insert(
      _table,
      {'key': _keyThemeMode, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getReduceStock() async {
    final value = await get(_keyReduceStock);
    return value == 'true';
  }

  Future<void> setReduceStock(bool value) async {
    await set(_keyReduceStock, value.toString());
  }

  Future<String?> get(String key) async {
    final db = await DatabaseHelper.instance.db;
    final result = await db.query(_table, where: 'key = ?', whereArgs: [key]);
    if (result.isEmpty) return null;
    return result.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    final db = await DatabaseHelper.instance.db;
    await db.insert(
      _table,
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}
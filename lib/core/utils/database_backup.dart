import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';

class DatabaseBackup {
  static Future<String> get backupDir async {
    final dir = await getApplicationDocumentsDirectory();
    final backup = Directory(p.join(dir.path, 'backups'));
    if (!await backup.exists()) await backup.create(recursive: true);
    return backup.path;
  }

  static Future<List<FileSystemEntity>> listBackups() async {
    final dir = await backupDir;
    final files = Directory(dir).listSync();
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files.where((f) => f.path.endsWith('.db')).toList();
  }

  static Future<String?> export() async {
    final helper = DatabaseHelper.instance;
    await helper.close();
    try {
      final src = await helper.dbPath;
      final destDir = await backupDir;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final dest = p.join(destDir, 'mobilepos_backup_$timestamp.db');
      await File(src).copy(dest);
      await Share.shareXFiles(
        [XFile(dest)],
        text: 'Backup Data Drone POS',
      );
      return null;
    } catch (e) {
      return e.toString();
    } finally {
      await helper.db;
    }
  }

  static Future<String?> restore(String path) async {
    final src = File(path);
    if (!await src.exists()) return 'File tidak ditemukan';

    // Verify SQLite header
    final header = await src.openRead(0, 16).first;
    if (header.length < 16 || !String.fromCharCodes(header).contains('SQLite format')) {
      return 'File bukan database SQLite yang valid';
    }

    final helper = DatabaseHelper.instance;
    await helper.close();
    try {
      final dbPath = await helper.dbPath;
      await File(dbPath).delete();
      await src.copy(dbPath);
      await helper.db;
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

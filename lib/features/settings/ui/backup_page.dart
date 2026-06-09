import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import '../../../core/utils/database_backup.dart';
import '../../../core/utils/responsive_dialog.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});
  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  List<FileSystemEntity> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final files = await DatabaseBackup.listBackups();
    if (mounted) setState(() { _files = files; _loading = false; });
  }

  String _fileSize(File f) {
    final kb = f.lengthSync() / 1024;
    return kb > 1024 ? '${(kb / 1024).toStringAsFixed(1)} MB' : '${kb.toStringAsFixed(0)} KB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Backup & Restore Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Export card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(Icons.backup, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 12),
                  Text('Backup Database',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('Ekspor data ke file .db dan bagikan.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.upload),
                      label: const Text('Backup & Share'),
                      onPressed: () => _export(context),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Restore section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('File Backup Tersimpan',
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Muat ulang'),
                    onPressed: _load,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else if (_files.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Icon(Icons.folder_off, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(height: 8),
                    Text('Belum ada file backup',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            )
          else
            ..._files.map((f) {
              final file = File(f.path);
              final name = p.basename(f.path);
              final date = DateFormat('dd/MM/yyyy HH:mm')
                  .format(file.statSync().modified);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text('$date • ${_fileSize(file)}'),
                  trailing: TextButton(
                    onPressed: () => _import(context, f.path),
                    child: const Text('Restore'),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext ctx) async {
    final scaffold = ScaffoldMessenger.of(ctx);
    showConstrainedDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final err = await DatabaseBackup.export();
    if (ctx.mounted) Navigator.pop(ctx);
    await _load();
    if (err != null) {
      scaffold.showSnackBar(SnackBar(content: Text('Gagal backup: $err')));
    }
  }

  Future<void> _import(BuildContext ctx, String path) async {
    final confirmed = await showConstrainedDialog<bool>(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Restore Data'),
        content: const Text(
          'Restore akan menghapus semua data saat ini dan menggantinya dengan data dari file backup. Lanjutkan?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dCtx, false),
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dCtx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Restore', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !ctx.mounted) return;

    final scaffold = ScaffoldMessenger.of(ctx);
    showConstrainedDialog(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    final err = await DatabaseBackup.restore(path);
    if (ctx.mounted) Navigator.pop(ctx);
    if (err != null) {
      scaffold.showSnackBar(SnackBar(content: Text('Gagal restore: $err')));
      return;
    }
    if (!ctx.mounted) return;
    scaffold.showSnackBar(const SnackBar(
        content: Text('Restore berhasil! Aplikasi akan dimuat ulang...')));
    await Future.delayed(const Duration(seconds: 1));
    if (ctx.mounted) {
      Navigator.pushNamedAndRemoveUntil(ctx, '/', (_) => false);
    }
  }
}

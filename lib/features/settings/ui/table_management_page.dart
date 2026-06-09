import 'package:flutter/material.dart';
import '../../../core/database/table_dao.dart';
import '../../../core/models/table.dart';

class TableManagementPage extends StatefulWidget {
  const TableManagementPage({super.key});

  @override
  State<TableManagementPage> createState() => _TableManagementPageState();
}

class _TableManagementPageState extends State<TableManagementPage> {
  final _dao = TableDao();
  List<RestoTable> _tables = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _tables = await _dao.getAll();
    setState(() => _loading = false);
  }

  Future<void> _add() async {
    final nameCtrl = TextEditingController();
    final capacityCtrl = TextEditingController(text: '4');
    final noteCtrl = TextEditingController();
    
    final result = await showDialog<RestoTable>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Meja'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Meja',
                hintText: 'Meja 1',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: capacityCtrl,
              decoration: const InputDecoration(
                labelText: 'Kapasitas',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty) return;
              Navigator.pop(ctx, RestoTable(
                name: nameCtrl.text,
                capacity: int.tryParse(capacityCtrl.text) ?? 4,
                note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                createdAt: DateTime.now().toIso8601String(),
              ));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      await _dao.insert(result);
      _load();
    }
  }

  Future<void> _edit(RestoTable tbl) async {
    final nameCtrl = TextEditingController(text: tbl.name);
    final capacityCtrl = TextEditingController(text: '${tbl.capacity}');
    final noteCtrl = TextEditingController(text: tbl.note ?? '');
    var isActive = tbl.isActive;
    
    final result = await showDialog<RestoTable?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Meja'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Meja'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: capacityCtrl,
                decoration: const InputDecoration(labelText: 'Kapasitas'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Catatan (opsional)'),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Aktif'),
                value: isActive,
                onChanged: (v) => setState(() => isActive = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty) return;
                Navigator.pop(ctx, tbl.copyWith(
                  name: nameCtrl.text,
                  capacity: int.tryParse(capacityCtrl.text) ?? 4,
                  note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  isActive: isActive,
                ));
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      await _dao.update(result);
      _load();
    }
  }

  Future<void> _delete(RestoTable tbl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Meja'),
        content: Text('Hapus ${tbl.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await _dao.delete(tbl.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Meja'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _add,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _tables.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.table_restaurant, size: 64, color: Colors.grey),
                      SizedBox(height: 8),
                      Text('Belum ada meja', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _tables.length,
                  itemBuilder: (ctx, i) {
                    final tbl = _tables[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${tbl.capacity}'),
                        ),
                        title: Text(tbl.name),
                        subtitle: tbl.note != null ? Text(tbl.note!) : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!tbl.isActive)
                              Chip(
                                label: const Text('Nonaktif'),
                                backgroundColor: Colors.red.shade100,
                              ),
                            PopupMenuButton(
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Text('Edit'),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Hapus', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                              onSelected: (v) {
                                if (v == 'edit') _edit(tbl);
                                if (v == 'delete') _delete(tbl);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
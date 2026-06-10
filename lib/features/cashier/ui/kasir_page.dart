import 'package:flutter/material.dart';
import '../../../core/database/user_dao.dart';
import '../../../core/models/user.dart';
import '../../../core/utils/responsive_dialog.dart';
import '../../../core/utils/responsive_page_insets.dart';

class KasirPage extends StatefulWidget {
  const KasirPage({super.key});

  @override
  State<KasirPage> createState() => _KasirPageState();
}

class _KasirPageState extends State<KasirPage> {
  final _dao = UserDao();
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<User> _users = [];
  int _totalCount = 0;
  bool _loading = false;
  bool _hasMore = true;
  String _search = '';
  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_loading || !_hasMore) return;
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _users = [];
      _hasMore = true;
    });

    final list = await _dao.getAllPaginated(
      limit: _pageSize,
      offset: 0,
      search: _search.isEmpty ? null : _search,
    );
    final count = await _dao.getCount(search: _search.isEmpty ? null : _search);

    if (mounted)
      setState(() {
        _users = list;
        _totalCount = count;
        _loading = false;
        _hasMore = list.length >= _pageSize;
      });
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);

    final list = await _dao.getAllPaginated(
      limit: _pageSize,
      offset: _users.length,
      search: _search.isEmpty ? null : _search,
    );

    if (mounted)
      setState(() {
        _users.addAll(list);
        _loading = false;
        _hasMore = list.length >= _pageSize;
      });
  }

  void _onSearch(String v) {
    _search = v;
    _load();
  }

  void _showForm([User? user]) {
    final nameCtrl = TextEditingController(text: user?.name);
    final usernameCtrl = TextEditingController(text: user?.username);
    final passCtrl = TextEditingController();
    String role = user?.role ?? 'kasir';

    showConstrainedDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(user == null ? 'Tambah Kasir' : 'Edit Kasir'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: usernameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: user == null
                        ? 'Password'
                        : 'Password Baru (kosong = tidak ganti)',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(
                        value: 'merchant', child: Text('Merchant')),
                    DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                  ],
                  onChanged: (v) => setState(() => role = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final username = usernameCtrl.text.trim();
                if (name.isEmpty || username.isEmpty) return;
                final newPass = passCtrl.text;
                if (user == null) {
                  if (newPass.isEmpty) return;
                  await _dao.insert(User(
                    name: name,
                    username: username,
                    password: newPass,
                    role: role,
                    isActive: true,
                    createdAt: DateTime.now().toIso8601String(),
                  ));
                } else {
                  await _dao.update(User(
                    id: user.id,
                    name: name,
                    username: username,
                    password: newPass.isEmpty ? user.password : newPass,
                    role: role,
                    isActive: user.isActive,
                    createdAt: user.createdAt,
                  ));
                }
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Kasir berhasil disimpan')),
                  );
                }
                _load();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleActive(User u) async {
    final newStatus = !u.isActive;
    final action = newStatus ? 'Aktifkan' : 'Nonaktifkan';
    final ok = await showConstrainedDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action Kasir'),
        content: Text('$action "${u.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus ? Colors.green : Colors.red,
            ),
            child: Text(action),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _dao.update(User(
      id: u.id,
      name: u.name,
      username: u.username,
      password: u.password,
      role: u.role,
      isActive: newStatus,
      createdAt: u.createdAt,
    ));
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kasir berhasil $action')),
      );
    }
  }

  Future<void> _delete(User u) async {
    final ok = await showConstrainedDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Kasir'),
        content: Text('Hapus "${u.name}"? Data tidak bisa dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _dao.hardDelete(u.id!);
    _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kasir berhasil dihapus')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manajemen Kasir')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: ResponsivePageInsets.horizontal(context, maxContentWidth: 680),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari kasir...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchCtrl.clear();
                            _onSearch('');
                          },
                        )
                      : null,
                ),
                onChanged: _onSearch,
              ),
            ),
            Expanded(
              child: _users.isEmpty && !_loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 48,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(height: 8),
                          Text(
                            _search.isEmpty
                                ? 'Belum ada kasir'
                                : 'Kasir tidak ditemukan',
                            style: TextStyle(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _users.length + (_hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= _users.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        final u = _users[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => _showForm(u),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: u.isActive
                                        ? Theme.of(context)
                                            .colorScheme
                                            .primaryContainer
                                        : Colors.grey[300],
                                    child: Text(
                                      u.name[0].toUpperCase(),
                                      style: TextStyle(
                                        color: u.isActive
                                            ? Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          u.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '@${u.username}',
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: u.role == 'admin'
                                                ? Colors.blue[100]
                                                : u.role == 'merchant'
                                                    ? Colors.purple[100]
                                                    : Colors.green[100],
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            u.role == 'admin'
                                                ? 'Admin'
                                                : u.role == 'merchant'
                                                    ? 'Merchant'
                                                    : 'Kasir',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: u.role == 'admin'
                                                  ? Colors.blue[700]
                                                  : u.role == 'merchant'
                                                      ? Colors.purple[700]
                                                      : Colors.green[700],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: u.isActive
                                              ? Colors.green[100]
                                              : Colors.red[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          u.isActive ? 'Aktif' : 'Nonaktif',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: u.isActive
                                                ? Colors.green[700]
                                                : Colors.red[700],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(
                                              u.isActive
                                                  ? Icons.block
                                                  : Icons.check_circle,
                                              color: u.isActive
                                                  ? Colors.orange
                                                  : Colors.green,
                                            ),
                                            onPressed: () => _toggleActive(u),
                                            tooltip: u.isActive
                                                ? 'Nonaktifkan'
                                                : 'Aktifkan',
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () => _delete(u),
                                            tooltip: 'Hapus',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            if (_totalCount > 0)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  '$_totalCount kasir',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

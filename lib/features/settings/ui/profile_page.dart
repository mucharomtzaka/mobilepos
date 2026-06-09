import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart' show DateFormat;
import '../../../core/database/user_dao.dart';
import '../../../core/models/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/utils/responsive_dialog.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _dao = UserDao();

  void _showEditDialog(User user) {
    final nameCtrl = TextEditingController(text: user.name);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    var saving = false;
    var currentRole = user.role;
    var isActive = user.isActive;
    final isAdminOrMerchant = user.role == 'admin' || user.role == 'merchant';

    showConstrainedDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Profil'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                  ),
                  if (isAdminOrMerchant) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: currentRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        prefixIcon: Icon(Icons.badge),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(value: 'merchant', child: Text('Merchant')),
                        DropdownMenuItem(value: 'kasir', child: Text('Kasir')),
                      ],
                      onChanged: (v) {
                        setDialogState(() => currentRole = v!);
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Status Akun'),
                      subtitle: Text(isActive ? 'Aktif' : 'Nonaktif'),
                      value: isActive,
                      onChanged: (v) {
                        setDialogState(() => isActive = v);
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: oldPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Lama',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (newPassCtrl.text.isNotEmpty && (v == null || v.isEmpty)) {
                        return 'Masukkan password lama';
                      }
                      if (v != null && v.isNotEmpty && v != user.password) {
                        return 'Password lama salah';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: newPassCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Password Baru (opsional)',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v != null && v.isNotEmpty && v.length < 4) {
                        return 'Minimal 4 karakter';
                      }
                      if (v != null && v.isNotEmpty && oldPassCtrl.text.isEmpty) {
                        return 'Isi password lama terlebih dahulu';
                      }
                      return null;
                    },
                  ),
                  if (newPassCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: confirmPassCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v != newPassCtrl.text) ? 'Password tidak cocok' : null,
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);

                      final isAdminOrMerchant = user.role == 'admin' || user.role == 'merchant';
                      final updated = User(
                        id: user.id,
                        name: nameCtrl.text.trim(),
                        username: user.username,
                        password: newPassCtrl.text.isNotEmpty
                            ? newPassCtrl.text
                            : user.password,
                        role: isAdminOrMerchant ? currentRole : user.role,
                        isActive: isAdminOrMerchant ? isActive : user.isActive,
                        createdAt: user.createdAt,
                      );
                      await _dao.update(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        context
                            .read<AuthBloc>()
                            .add(AuthProfileUpdated(updated));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Profil berhasil diperbarui')),
                        );
                      }
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = authState.user;
    final theme = Theme.of(context);

    final initial = user.name.isNotEmpty
        ? user.name.substring(0, 1).toUpperCase()
        : '?';

    final createdAt = DateTime.tryParse(user.createdAt) ?? DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(createdAt);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Profil',
            onPressed: () => _showEditDialog(user),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.primaryColor,
                  child: Text(
                    initial,
                    style: const TextStyle(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: user.role == 'admin'
                        ? Colors.amber.withValues(alpha: 0.15)
                        : user.role == 'merchant'
                            ? Colors.purple.withValues(alpha: 0.15)
                            : Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user.role == 'admin' ? 'Admin' : user.role == 'merchant' ? 'Merchant' : 'Kasir',
                    style: TextStyle(
                      color: user.role == 'admin' ? Colors.amber[800] : user.role == 'merchant' ? Colors.purple : Colors.blue,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Info
          _infoCard(
            context,
            children: [
              _infoRow(Icons.person, 'Nama', user.name),
              const Divider(height: 1),
              _infoRow(Icons.account_circle, 'Username', user.username),
              const Divider(height: 1),
              _infoRow(Icons.badge, 'Role', user.role == 'admin' ? 'Admin' : user.role == 'merchant' ? 'Merchant' : 'Kasir'),
              const Divider(height: 1),
              _infoRow(Icons.calendar_today, 'Bergabung', dateStr),
              const Divider(height: 1),
              _infoRow(
                Icons.check_circle,
                'Status',
                user.isActive ? 'Aktif' : 'Nonaktif',
                valueColor: user.isActive ? Colors.green : Colors.red,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                showConstrainedDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Keluar'),
                    content: const Text('Yakin ingin keluar?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          context.read<AuthBloc>().add(AuthLogoutRequested());
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        child: const Text('Keluar',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Keluar', style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(BuildContext context,
      {required List<Widget> children}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(children: children),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value,
      {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}

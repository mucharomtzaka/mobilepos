import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../cashier/ui/kasir_page.dart';
import '../../cashier/ui/printer_settings_page.dart';
import '../../cashier/ui/receipt_settings_page.dart';
import '../../cashier/ui/transaction_settings_page.dart';
import '../../customer/ui/customer_page.dart';
import '../../product/bloc/product_bloc.dart';
import '../../product/bloc/stock_bloc.dart';
import '../../product/ui/category_page.dart';
import '../../product/ui/product_page.dart';
import '../../product/ui/stock_page.dart';
import '../../shift/ui/shift_page.dart';
import '../../cashflow/ui/finance_page.dart';

import '../ui/backup_page.dart';
import '../ui/theme_page.dart';
import '../ui/profile_page.dart';
import '../ui/table_management_page.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/database/stock_dao.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../../core/utils/crash_reporter.dart';
import '../../cart/bloc/cart_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = (authState is AuthAuthenticated) ? authState.user : null;
    final isAdmin = user?.role == 'admin' || user?.role == 'merchant';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person,
            title: 'Profil',
            subtitle: user != null ? '${user.name} • ${user.role == 'admin' ? 'Admin' : user.role == 'merchant' ? 'Merchant' : 'Kasir'}' : '',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.print,
            title: 'Printer',
            subtitle: 'Pengaturan printer Bluetooth',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PrinterSettingsPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.receipt,
            title: 'Struk',
            subtitle: 'Nama toko, alamat, pajak, logo',
            onTap: () {
              final cartBloc = context.read<CartBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReceiptSettingsPage()),
              ).then((_) {
                cartBloc.add(CartSetTaxPercent(ReceiptSettings.taxPercent));
              });
            },
          ),
          _SettingsTile(
            icon: Icons.settings_applications,
            title: 'Transaksi',
            subtitle: 'Kelola stok otomatis & pembatalan transaksi',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TransactionSettingsPage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.people,
            title: 'Kelola Pelanggan',
            subtitle: 'Tambah, edit, dan hapus pelanggan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.table_restaurant,
            title: 'Kelola Meja',
            subtitle: 'Tambah, edit, dan hapus meja resto',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TableManagementPage()),
            ),
          ),
          if (isAdmin)
            _SettingsTile(
              icon: Icons.person_add,
              title: 'Kelola Kasir',
              subtitle: 'Tambah, edit, dan hapus akun kasir',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KasirPage()),
              ),
            ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.category,
            title: 'Kelola Kategori',
            subtitle: 'Tambah, edit, dan hapus kategori produk',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.inventory,
            title: 'Kelola Produk',
            subtitle: 'Tambah, edit, dan hapus produk',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => ProductBloc(ProductDao(), CategoryDao()),
                  child: const ProductPage(),
                ),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.warehouse,
            title: 'Kelola Stok',
            subtitle: 'Kelola stok produk',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (_) => StockBloc(ProductDao(), StockDao()),
                  child: StockPage(isAdmin: isAdmin),
                ),
              ),
            ),
          ),
          _SettingsTile(
            icon: Icons.schedule,
            title: 'Kelola Shift',
            subtitle: 'Buka atau tutup shift kasir',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShiftPage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.account_balance,
            title: 'Kelola Keuangan',
            subtitle: 'Pemasukan, pengeluaran, dan laporan',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinancePage()),
            ),
          ),
          const Divider(height: 24),
          if (isAdmin)
            _SettingsTile(
              icon: Icons.backup,
              title: 'Backup & Restore',
              subtitle: 'Cadangkan atau pulihkan data',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupPage()),
              ),
            ),
          _SettingsTile(
            icon: Icons.palette,
            title: 'Tema',
            subtitle: 'Terang, gelap, atau ikuti sistem',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemePage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.info,
            title: 'Tentang Aplikasi',
            subtitle: 'Informasi aplikasi DronePos',
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'DronePos UMKM',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 DronePos',
              children: [
                const SizedBox(height: 16),
                const Text('Aplikasi kasir modern untuk bisnis retail. Mendukung pencatatan transaksi, laporan, manajemen produk, pelanggan, dan banyak lagi'),
              ],
            ),
          ),
          _SettingsTile(
            icon: Icons.email,
            title: 'Email Kontak',
            subtitle: 'poslitedrone@gmail.com',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email: poslitedrone@gmail.com')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.bug_report,
            title: 'Laporkan Masalah',
            subtitle: 'Kirim laporan crash / ANR ke pengembang',
            onTap: () => CrashReporter().sendReport(),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        radius: 22,
        child: Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

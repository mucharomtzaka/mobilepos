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
import '../../product/ui/bundle_form_page.dart';
import '../../product/ui/category_page.dart';
import '../../product/ui/product_page.dart';
import '../../product/ui/stock_page.dart';
import '../../shift/ui/shift_page.dart';
import '../../cashflow/ui/finance_page.dart';

import '../ui/backup_page.dart';
import '../ui/theme_page.dart';
import '../ui/profile_page.dart';
import '../ui/privacy_policy_page.dart';
import '../ui/table_management_page.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/database/stock_dao.dart';
import '../../../core/bloc/locale_bloc.dart';
import '../../../core/utils/responsive_page_insets.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../../core/utils/crash_reporter.dart';
import '../../../core/api/sync_page.dart';
import '../../../l10n/app_localizations.dart';
import '../../cart/bloc/cart_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = (authState is AuthAuthenticated) ? authState.user : null;
    final isAdmin = user?.role == 'admin' || user?.role == 'merchant';
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: ResponsivePageInsets.horizontal(context, maxContentWidth: 620),
        children: [
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.person,
            title: l10n.settingsProfile,
            subtitle: user != null
                ? '${user.name} • ${user.role == 'admin' ? 'Admin' : user.role == 'merchant' ? 'Merchant' : 'Kasir'}'
                : '',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.print,
            title: l10n.settingsPrinter,
            subtitle: l10n.settingsPrinterSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrinterSettingsPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.receipt,
            title: l10n.settingsReceipt,
            subtitle: l10n.settingsReceiptSubtitle,
            onTap: () {
              final cartBloc = context.read<CartBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ReceiptSettingsPage()),
              ).then((_) {
                cartBloc.add(CartSetTaxPercent(ReceiptSettings.taxPercent));
              });
            },
          ),
          _SettingsTile(
            icon: Icons.settings_applications,
            title: l10n.settingsTransaction,
            subtitle: l10n.settingsTransactionSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const TransactionSettingsPage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.people,
            title: l10n.settingsCustomer,
            subtitle: l10n.settingsCustomerSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CustomerPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.table_restaurant,
            title: l10n.settingsTable,
            subtitle: l10n.settingsTableSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TableManagementPage()),
            ),
          ),
          if (isAdmin)
            _SettingsTile(
              icon: Icons.person_add,
              title: l10n.settingsCashier,
              subtitle: l10n.settingsCashierSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KasirPage()),
              ),
            ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.category,
            title: l10n.settingsCategory,
            subtitle: l10n.settingsCategorySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CategoryPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.inventory,
            title: l10n.settingsProduct,
            subtitle: l10n.settingsProductSubtitle,
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
            icon: Icons.redeem,
            title: l10n.settingsBundle,
            subtitle: l10n.settingsBundleSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BundlePage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.warehouse,
            title: l10n.settingsStock,
            subtitle: l10n.settingsStockSubtitle,
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
            title: l10n.settingsShift,
            subtitle: l10n.settingsShiftSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ShiftPage()),
            ),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.account_balance,
            title: l10n.settingsFinance,
            subtitle: l10n.settingsFinanceSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FinancePage()),
            ),
          ),
          const Divider(height: 24),
          if (isAdmin)
            _SettingsTile(
              icon: Icons.backup,
              title: l10n.settingsBackup,
              subtitle: l10n.settingsBackupSubtitle,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BackupPage()),
              ),
            ),
          if (isAdmin)
            _SettingsTile(
              icon: Icons.cloud_sync,
              title: 'Sync Server',
              subtitle: 'Sinkronisasi data dengan server',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SyncPage()),
              ),
            ),
          _SettingsTile(
            icon: Icons.palette,
            title: l10n.settingsTheme,
            subtitle: l10n.settingsThemeSubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ThemePage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.language,
            title: l10n.language,
            subtitle: l10n.languageSubtitle,
            onTap: () => _showLanguagePicker(context),
          ),
          const Divider(height: 24),
          _SettingsTile(
            icon: Icons.privacy_tip,
            title: l10n.settingsPrivacy,
            subtitle: l10n.settingsPrivacySubtitle,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyPage()),
            ),
          ),
          _SettingsTile(
            icon: Icons.info,
            title: l10n.settingsAbout,
            subtitle: l10n.settingsAboutSubtitle,
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'DronePos UMKM',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 DronePos',
              children: [
                const SizedBox(height: 16),
                Text(l10n.settingsAboutSubtitle),
              ],
            ),
          ),
          _SettingsTile(
            icon: Icons.email,
            title: l10n.settingsEmail,
            subtitle: l10n.settingsEmailSubtitle,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Email: ${l10n.settingsEmailSubtitle}')),
              );
            },
          ),
          _SettingsTile(
            icon: Icons.bug_report,
            title: l10n.settingsReport,
            subtitle: l10n.settingsReportSubtitle,
            onTap: () => CrashReporter().sendReport(),
          ),
        ],
      ),
    );
  }
}

void _showLanguagePicker(BuildContext context) {
  final locale = context.read<LocaleBloc>().state;
  final l10n = AppLocalizations.of(context)!;
  showDialog(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(l10n.language),
      children: [
        RadioListTile<Locale>(
          title: Text(l10n.languageIndonesian),
          subtitle: const Text('Bahasa Indonesia'),
          value: const Locale('id', 'ID'),
          groupValue: locale,
          onChanged: (v) {
            context.read<LocaleBloc>().add(v!);
            Navigator.pop(ctx);
          },
        ),
        RadioListTile<Locale>(
          title: Text(l10n.languageEnglish),
          subtitle: const Text('English'),
          value: const Locale('en', 'US'),
          groupValue: locale,
          onChanged: (v) {
            context.read<LocaleBloc>().add(v!);
            Navigator.pop(ctx);
          },
        ),
      ],
    ),
  );
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
        child:
            Icon(icon, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: Icon(Icons.chevron_right,
          color: Theme.of(context).colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

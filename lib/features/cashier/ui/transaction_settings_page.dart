import 'package:flutter/material.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../../core/database/settings_dao.dart';
import '../../../core/utils/responsive_page_insets.dart';

class TransactionSettingsPage extends StatefulWidget {
  const TransactionSettingsPage({super.key});
  @override
  State<TransactionSettingsPage> createState() =>
      _TransactionSettingsPageState();
}

class _TransactionSettingsPageState extends State<TransactionSettingsPage> {
  final _dao = SettingsDao();
  late bool _manageStock;
  late bool _allowCancel;
  final _cancelPwdCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _manageStock = ReceiptSettings.manageStock;
    _allowCancel = false;
    _load();
  }

  Future<void> _load() async {
    final allowCancel = await _dao.get('allow_cancel_transactions');
    final cancelPwd = await _dao.get('cancel_password');
    if (mounted) {
      setState(() {
        _allowCancel = allowCancel == 'true';
        _cancelPwdCtrl.text = cancelPwd ?? '';
      });
    }
  }

  @override
  void dispose() {
    _cancelPwdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    await ReceiptSettings.save(
      storeName: ReceiptSettings.storeName,
      address: ReceiptSettings.address,
      phone: ReceiptSettings.phone,
      header: ReceiptSettings.header,
      footer: ReceiptSettings.footer,
      logoPath: ReceiptSettings.logoPath,
      taxPercent: ReceiptSettings.taxPercent,
      manageStock: _manageStock,
    );
    await _dao.set('allow_cancel_transactions', _allowCancel.toString());
    if (_cancelPwdCtrl.text.isNotEmpty) {
      await _dao.set('cancel_password', _cancelPwdCtrl.text);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan transaksi disimpan')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Transaksi')),
      body: ListView(
        padding: ResponsivePageInsets.content(
          context,
          maxContentWidth: 720,
          top: 16,
          bottom: 16,
        ),
        children: [
          const Text('Kelola Stok',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Kurangi Stok Otomatis'),
            subtitle: const Text(
              'Kurangi stok otomatis saat transaksi dan cek ketersediaan stok',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _manageStock,
            onChanged: (v) => setState(() => _manageStock = v),
          ),
          const Divider(height: 32),
          const Text('Pembatalan Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Izinkan Pembatalan'),
            subtitle: const Text(
              'Izinkan membatalkan transaksi di halaman struk',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            value: _allowCancel,
            onChanged: (v) => setState(() => _allowCancel = v),
          ),
          if (_allowCancel) ...[
            const SizedBox(height: 8),
            TextField(
              controller: _cancelPwdCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password Pembatalan',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                helperText: 'Password untuk membatalkan transaksi',
              ),
            ),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Simpan'),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/utils/custom_image_picker.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../../core/utils/responsive_dialog.dart';
import '../../../core/utils/responsive_page_insets.dart';

class ReceiptSettingsPage extends StatefulWidget {
  const ReceiptSettingsPage({super.key});
  @override
  State<ReceiptSettingsPage> createState() => _ReceiptSettingsPageState();
}

class _ReceiptSettingsPageState extends State<ReceiptSettingsPage> {
  late final TextEditingController _storeName;
  late final TextEditingController _address;
  late final TextEditingController _phone;
  late final TextEditingController _header;
  late final TextEditingController _footer;
  late final TextEditingController _taxPercent;
  String? _logoPath;
  bool _cashDrawer = ReceiptSettings.cashDrawer;

  @override
  void initState() {
    super.initState();
    _storeName = TextEditingController(text: ReceiptSettings.storeName);
    _address = TextEditingController(text: ReceiptSettings.address);
    _phone = TextEditingController(text: ReceiptSettings.phone);
    _header = TextEditingController(text: ReceiptSettings.header);
    _footer = TextEditingController(text: ReceiptSettings.footer);
    _taxPercent = TextEditingController(
        text: ReceiptSettings.taxPercent.toStringAsFixed(0));
    _logoPath = ReceiptSettings.logoPath;
  }

  @override
  void dispose() {
    for (final c in [
      _storeName,
      _address,
      _phone,
      _header,
      _footer,
      _taxPercent
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  bool _isPickingLogo = false;
  final _imagePicker = ImagePicker();

  Future<void> _pickLogo(bool fromCamera) async {
    if (_isPickingLogo) return;
    _isPickingLogo = true;

    try {
      if (fromCamera) {
        final status = await Permission.camera.request();
        if (!status.isGranted) {
          if (status.isPermanentlyDenied) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                      'Izin kamera ditolak permanen. Izinkan di pengaturan aplikasi.'),
                  action: const SnackBarAction(
                    label: 'Buka Pengaturan',
                    onPressed: openAppSettings,
                  ),
                ),
              );
            }
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin kamera ditolak')),
            );
          }
          return;
        }
        final picked = await _imagePicker.pickImage(
          source: ImageSource.camera,
          maxWidth: 300,
          imageQuality: 80,
        );
        if (picked != null) {
          final dir = await getApplicationDocumentsDirectory();
          final ext = picked.path.split('.').last;
          final targetPath = '${dir.path}/receipt_logo.$ext';
          await File(picked.path).copy(targetPath);
          if (mounted) setState(() => _logoPath = targetPath);
        }
      } else {
        final granted = await CustomImagePicker.requestGalleryPermission();
        if (!granted) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Izin galeri ditolak')),
            );
          }
          return;
        }
        if (mounted) {
          final path = await CustomImagePicker.pickImage(context);
          if (path != null && mounted) {
            setState(() => _logoPath = path);
          }
        }
      }
    } finally {
      _isPickingLogo = false;
    }
  }

  void _showLogoOptions() {
    showConstrainedModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil Foto'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickLogo(false);
              },
            ),
            if (_logoPath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Hapus Logo',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  setState(() => _logoPath = null);
                  Navigator.pop(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showPreview() {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    const hr = Divider(thickness: 1, color: Colors.black);

    showConstrainedDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_logoPath != null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Image.file(
                            File(_logoPath!),
                            width: 80,
                            height: 80,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    Center(
                      child: Text(
                        _storeName.text.trim().isNotEmpty
                            ? _storeName.text.trim()
                            : 'UMKM Store',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    if (_address.text.trim().isNotEmpty)
                      Center(
                        child: Text(
                          _address.text.trim(),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (_phone.text.trim().isNotEmpty)
                      Center(
                        child: Text(
                          'Telp: ${_phone.text.trim()}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    if (_header.text.trim().isNotEmpty) ...[
                      hr,
                      Center(
                        child: Text(
                          _header.text.trim(),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    hr,
                    Text(
                      'No: STR-20241201-001\n${dateFmt.format(DateTime.now())}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    hr,
                    _itemRow('Produk Contoh 1', 2, 15000, 30000, fmt),
                    _itemRow('Produk Contoh 2 Panjang', 1, 25000, 25000, fmt),
                    hr,
                    _row('Subtotal', fmt.format(45000)),
                    _row('Diskon', '- ${fmt.format(5000)}',
                        color: Colors.green),
                    _PajakRow(
                        40000, double.tryParse(_taxPercent.text) ?? 0, fmt),
                    _row(
                        'TOTAL',
                        fmt.format(_totalWithTax(45000, 5000,
                            double.tryParse(_taxPercent.text) ?? 0)),
                        bold: true),
                    hr,
                    _row('Tunai', fmt.format(50000)),
                    _row('Kembalian', fmt.format(10000),
                        bold: true, color: Colors.blue),
                    hr,
                    if (_footer.text.trim().isNotEmpty)
                      Center(
                        child: Text(
                          _footer.text.trim(),
                          style: const TextStyle(fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _itemRow(
      String name, int qty, double price, double subtotal, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '$name\n$qty x ${fmt.format(price)}',
              style: const TextStyle(fontSize: 11),
            ),
          ),
          Text(fmt.format(subtotal), style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  double _totalWithTax(double sub, double disc, double taxPct) {
    final base = sub - disc;
    return base + (base * taxPct / 100);
  }

  Widget _PajakRow(double base, double taxPct, NumberFormat fmt) {
    if (taxPct <= 0) return const SizedBox();
    final tax = base * taxPct / 100;
    return _row('Pajak $taxPct%', fmt.format(tax));
  }

  Widget _row(String l, String v, {bool bold = false, Color? color}) {
    final s = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      color: color,
      fontSize: 11,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(l, style: s), Text(v, style: s)],
      ),
    );
  }

  Future<void> _save() async {
    await ReceiptSettings.save(
      storeName: _storeName.text.trim(),
      address: _address.text.trim(),
      phone: _phone.text.trim(),
      header: _header.text.trim(),
      footer: _footer.text.trim(),
      logoPath: _logoPath,
      taxPercent: double.tryParse(_taxPercent.text) ?? 0,
      cashDrawer: _cashDrawer,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pengaturan struk disimpan')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan Struk')),
      body: ListView(
        padding: ResponsivePageInsets.content(
          context,
          maxContentWidth: 760,
          top: 16,
          bottom: 16 + MediaQuery.of(context).padding.bottom,
        ),
        children: [
          GestureDetector(
            onTap: _showLogoOptions,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _logoPath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_logoPath!),
                        fit: BoxFit.contain,
                        width: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo,
                            size: 36, color: Colors.grey[400]),
                        const SizedBox(height: 6),
                        Text('Upload Logo Struk',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showPreview,
            icon: const Icon(Icons.visibility),
            label: const Text('Lihat Preview Struk'),
          ),
          const SizedBox(height: 20),
          _field(_storeName, 'Nama Toko / Usaha', Icons.store, required: true),
          const SizedBox(height: 12),
          _field(_address, 'Alamat (opsional)', Icons.location_on),
          const SizedBox(height: 12),
          _field(_phone, 'No. Telepon (opsional)', Icons.phone,
              type: TextInputType.phone),
          const SizedBox(height: 20),
          const Text('Pajak (PPN)',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Persentase pajak yang ditambahkan ke total belanja',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _taxPercent,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              suffixText: '%',
              hintText: '0',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Header Struk',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Teks yang muncul di atas setelah nama toko',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _header,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Contoh: Selamat datang di toko kami...',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Footer Struk',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Teks yang muncul di bawah total pembayaran',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          TextField(
            controller: _footer,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText:
                  'Contoh: Terima kasih, barang yang dibeli tidak dapat dikembalikan.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Buka Laci Uang'),
            subtitle: const Text(
              'Laci uang akan terbuka otomatis saat struk dicetak',
              style: TextStyle(fontSize: 12),
            ),
            value: _cashDrawer,
            onChanged: (v) => setState(() => _cashDrawer = v),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Simpan Pengaturan'),
          ),
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    bool required = false,
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}

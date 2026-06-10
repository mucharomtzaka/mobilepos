import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/models/order.dart';
import '../../../core/utils/bluetooth_printer.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/database/user_dao.dart';
import '../../../core/database/customer_dao.dart';
import '../../../core/database/table_dao.dart';
import '../../../core/database/settings_dao.dart';
import '../../home_page.dart';
import '../../../core/utils/responsive_dialog.dart';

class ReceiptPage extends StatefulWidget {
  final Order order;
  final double change;
  const ReceiptPage({super.key, required this.order, required this.change});
  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  List<OrderItem> _items = [];
  List<PaymentEntry> _payments = [];
  String _cashierName = '';
  String _customerName = '';
  String _tableName = '';
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    final dao = OrderDao();
    final userDao = UserDao();
    final customerDao = CustomerDao();
    final items = await dao.getItemsByOrderId(widget.order.id!);
    final payments = await dao.getPaymentsByOrderId(widget.order.id!);
    final user = await userDao.getById(widget.order.userId);
    String customerName = '';
    if (widget.order.customerId != null) {
      final customer = await customerDao.getById(widget.order.customerId!);
      customerName = customer?.name ?? '';
    }
    String tableName = '';
    if (widget.order.tableId != null) {
      final table = await TableDao().getById(widget.order.tableId!);
      tableName = table?.name ?? '';
    }
    if (mounted) setState(() {
      _items = items;
      _payments = payments;
      _cashierName = user?.name ?? '';
      _customerName = customerName;
      _tableName = tableName;
    });
  }

  Future<void> _print() async {
    setState(() => _printing = true);
    
    // Check Bluetooth state first
    final state = await FlutterBluePlus.adapterState.first;
    if (state != BluetoothAdapterState.on) {
      if (mounted) {
        setState(() => _printing = false);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Bluetooth Mati'),
            content: const Text('Nyalakan Bluetooth untuk memindai printer.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await FlutterBluePlus.turnOn();
                  _print();
                },
                child: const Text('Nyalakan'),
              ),
            ],
          ),
        );
      }
      return;
    }
    
    // Try auto-reconnect to saved device first
    final connected = BluetoothPrinter.isConnected ||
        await BluetoothPrinter.ensureConnected();

    if (!connected) {
      if (mounted) setState(() => _printing = false);
      _showBluetoothPicker();
      return;
    }

    try {
      await BluetoothPrinter.printReceipt(
        order: widget.order,
        items: _items,
        payments: _payments,
        change: widget.change,
        cashierName: _cashierName,
        customerName: _customerName,
      );
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Struk dicetak!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal cetak: $e')));
      }
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _showBluetoothPicker() {
    showConstrainedModalBottomSheet(
      context: context,
      builder: (_) => _BluetoothPickerSheet(
        onConnected: () {
          Navigator.pop(context);
          _print();
        },
      ),
    );
  }

  Future<void> _shareReceipt() async {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');

    final buffer = StringBuffer();
    buffer.writeln(ReceiptSettings.storeName.isNotEmpty ? ReceiptSettings.storeName : 'UMKM Store');
    if (ReceiptSettings.address.isNotEmpty) buffer.writeln(ReceiptSettings.address);
    if (ReceiptSettings.phone.isNotEmpty) buffer.writeln('Telp: ${ReceiptSettings.phone}');
    buffer.writeln('--------------------------------');
    buffer.writeln('No: ${widget.order.orderNumber}');
    buffer.writeln(dateFmt.format(DateTime.parse(widget.order.createdAt)));
    if (_cashierName.isNotEmpty) buffer.writeln('Kasir: $_cashierName');
    if (_customerName.isNotEmpty) buffer.writeln('Pelanggan: $_customerName');
    if (_tableName.isNotEmpty) buffer.writeln('Meja: $_tableName');
    if (widget.order.note != null && widget.order.note!.isNotEmpty) buffer.writeln('Catatan: ${widget.order.note}');
    buffer.writeln('--------------------------------');

    int _gcd(int a, int b) {
      while (b != 0) {
        final t = b;
        b = a % b;
        a = t;
      }
      return a;
    }
    int i = 0;
    while (i < _items.length) {
      if (_items[i].bundleName != null) {
        final bundleName = _items[i].bundleName!;
        final group = <OrderItem>[];
        while (i < _items.length && _items[i].bundleName == bundleName) {
          group.add(_items[i]);
          i++;
        }
        final total = group.fold<double>(0, (s, it) => s + it.subtotal);
        final instances = group.map((it) => it.qty).reduce(_gcd);
        buffer.writeln('[BUNDLING] $bundleName');
        for (final it in group) {
          buffer.writeln('  ${it.qty ~/ instances}x ${it.productName}');
        }
        buffer.writeln('  ${instances}x ${fmt.format(total / instances)}');
        buffer.writeln('  ${fmt.format(total)}');
      } else {
        final it = _items[i];
        i++;
        final name = it.variantName != null
            ? '${it.productName} - ${it.variantName}'
            : it.productName;
        buffer.writeln('${it.qty} x ${fmt.format(it.price)}');
        buffer.writeln('$name');
        buffer.writeln(fmt.format(it.subtotal));
      }
    }

    buffer.writeln('--------------------------------');
    buffer.writeln('Subtotal: ${fmt.format(widget.order.subtotal)}');
    if (widget.order.discountAmount > 0) {
      buffer.writeln('Diskon: -${fmt.format(widget.order.discountAmount)}');
    }
    if (widget.order.taxPercent > 0) {
      buffer.writeln('Pajak ${widget.order.taxPercent.toStringAsFixed(0)}%: ${fmt.format(widget.order.taxAmount)}');
    }
    buffer.writeln('TOTAL: ${fmt.format(widget.order.total)}');
    buffer.writeln('--------------------------------');

    for (final p in _payments) {
      buffer.writeln('${p.method.label}: ${fmt.format(p.amount)}');
    }
    buffer.writeln('Uang Dibayar: ${fmt.format(widget.order.total + widget.change)}');
    if (widget.change > 0) {
      buffer.writeln('Kembalian: ${fmt.format(widget.change)}');
    }

    buffer.writeln('');
    buffer.writeln(ReceiptSettings.footer.isNotEmpty ? ReceiptSettings.footer : 'Terima kasih!');

    await Share.share(
      buffer.toString(),
      subject: 'Struk ${widget.order.orderNumber}',
    );
  }

  Future<void> _cancelTransaction() async {
    // Check if cancel is allowed in settings
    final settingDao = SettingsDao();
    final allowCancel = await settingDao.get('allow_cancel_transactions');
    if (allowCancel != 'true') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pembatalan transaksi tidak diizinkan')),
        );
      }
      return;
    }

    // Show password dialog
    final passwordController = TextEditingController();
    final passwordError = ValueNotifier<bool>(false);
    final confirmed = await showConstrainedDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batal Transaksi'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan password untuk membatalkan transaksi ini:'),
              const SizedBox(height: 16),
              ValueListenableBuilder<bool>(
                valueListenable: passwordError,
                builder: (_, error, __) => TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    errorText: error ? 'Password salah' : null,
                  ),
                  onSubmitted: (_) async {
                    final valid = await _validatePassword(passwordController.text);
                    if (ctx.mounted) Navigator.pop(ctx, valid);
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final valid = await _validatePassword(passwordController.text);
              if (ctx.mounted) Navigator.pop(ctx, valid);
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Perform cancellation
    final orderDao = OrderDao();
    await orderDao.updateStatus(widget.order.id!, 'cancelled');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi dibatalkan')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    }
  }

  Future<bool> _validatePassword(String password) async {
    final settingDao = SettingsDao();
    final storedPassword = await settingDao.get('cancel_password');
    return storedPassword == password;
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final isCancelled = widget.order.status == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text(isCancelled ? 'Struk (Dibatalkan)' : 'Struk'),
        actions: [
          if (!isCancelled)
            IconButton(
              icon: const Icon(Icons.cancel_outlined),
              onPressed: _cancelTransaction,
              tooltip: 'Batal Transaksi',
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareReceipt,
            tooltip: 'Bagikan',
          ),
          IconButton(
            icon: _printing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.print),
            onPressed: _printing || isCancelled ? null : _print,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (_, constraints) {
          final isWide = constraints.maxWidth > 800;
          final body = Column(
            children: [
              if (isCancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red.shade100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cancel, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Text(
                        'TRANSAKSI DIBATALKAN',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (ReceiptSettings.logoPath != null)
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Image.file(
                                      File(ReceiptSettings.logoPath!),
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              Center(
                                child: Text(
                                    ReceiptSettings.storeName.isNotEmpty
                                        ? ReceiptSettings.storeName
                                        : 'UMKM Store',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                              ),
                              if (ReceiptSettings.address.isNotEmpty)
                                Center(
                                  child: Text(ReceiptSettings.address,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center),
                                ),
                              if (ReceiptSettings.phone.isNotEmpty)
                                Center(
                                  child: Text('Telp: ${ReceiptSettings.phone}',
                                      style: const TextStyle(fontSize: 12)),
                                ),
                              if (ReceiptSettings.header.isNotEmpty) ...[
                                const Divider(),
                                Center(
                                  child: Text(ReceiptSettings.header,
                                      style: const TextStyle(fontSize: 12),
                                      textAlign: TextAlign.center),
                                ),
                              ],
                              const Divider(),
                              Text('No: ${widget.order.orderNumber}'),
                              Text(dateFmt.format(
                                  DateTime.parse(widget.order.createdAt))),
                              if (_cashierName.isNotEmpty)
                                Text('Kasir: $_cashierName'),
                              if (_customerName.isNotEmpty)
                                Text('Pelanggan: $_customerName'),
                              if (_tableName.isNotEmpty)
                                Text('Meja: $_tableName'),
                              if (widget.order.note != null && widget.order.note!.isNotEmpty)
                                Text('Catatan: ${widget.order.note}'),
                              const Divider(),
                              ..._buildReceiptItems(),
                              const Divider(),
                              if (widget.order.discountAmount > 0 ||
                                  widget.order.taxPercent > 0) ...[
                                if (widget.order.discountAmount > 0 ||
                                    widget.order.taxPercent > 0)
                                  _receiptRow('Subtotal',
                                      fmt.format(widget.order.subtotal)),
                                if (widget.order.discountAmount > 0)
                                  _receiptRow('Diskon',
                                      '- ${fmt.format(widget.order.discountAmount)}',
                                      color: Colors.green),
                                if (widget.order.taxPercent > 0)
                                  _receiptRow(
                                      'Pajak ${widget.order.taxPercent.toStringAsFixed(0)}%',
                                      fmt.format(widget.order.taxAmount),
                                      color: Colors.blue),
                              ],
                              _receiptRow(
                                  'TOTAL', fmt.format(widget.order.total),
                                  bold: true),
                              const Divider(),
                              ..._payments.map((p) => _receiptRow(
                                  p.method.label, fmt.format(p.amount))),
                              _receiptRow('Uang Dibayar', fmt.format(
                                  widget.order.total + widget.change), bold: true),
                              if (widget.change > 0)
                                _receiptRow('Kembalian', fmt.format(widget.change), color: Colors.blue),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  ReceiptSettings.footer.isNotEmpty
                                      ? ReceiptSettings.footer
                                      : 'Terima kasih!',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: isWide
                      ? Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () {
                                      context.read<CartBloc>().add(CartClear());
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => const HomePage()),
                                        (_) => false,
                                      );
                                    },
                                    child: const Text('Transaksi Baru'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _printing ? null : _print,
                                    icon: const Icon(Icons.print),
                                    label: const Text('Cetak'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  context.read<CartBloc>().add(CartClear());
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const HomePage()),
                                    (_) => false,
                                  );
                                },
                                child: const Text('Transaksi Baru'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _printing ? null : _print,
                                icon: const Icon(Icons.print),
                                label: const Text('Cetak'),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
          return isWide
              ? Center(
                  child: SizedBox(
                    width: 800,
                    child: body,
                  ),
                )
              : body;
        },
      ),
    );
  }

  List<Widget> _buildReceiptItems() {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final items = <Widget>[];
    int i = 0;
    int _gcd(int a, int b) {
      while (b != 0) {
        final t = b;
        b = a % b;
        a = t;
      }
      return a;
    }
    while (i < _items.length) {
      if (_items[i].bundleName != null) {
        final bundleName = _items[i].bundleName!;
        final group = <OrderItem>[];
        while (i < _items.length && _items[i].bundleName == bundleName) {
          group.add(_items[i]);
          i++;
        }
        final total = group.fold<double>(0, (s, it) => s + it.subtotal);
        final instances = group.map((it) => it.qty).reduce(_gcd);
        items.add(Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 2),
          child: Row(
            children: [
              Icon(Icons.redeem, size: 14, color: Colors.orange),
              const SizedBox(width: 4),
              Text(bundleName,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.orange)),
            ],
          ),
        ));
        for (final it in group) {
          items.add(Padding(
            padding: const EdgeInsets.only(left: 22, bottom: 1),
            child: Text('${it.qty ~/ instances}x ${it.productName}',
                style: const TextStyle(fontSize: 12)),
          ));
        }
        items.add(Padding(
          padding: const EdgeInsets.only(left: 22, top: 2),
          child: Row(
            children: [
              Text('${instances}x ${fmt.format(total / instances)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(fmt.format(total),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ));
      } else {
        final it = _items[i];
        i++;
        items.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                  child: Text(
                      it.variantName != null
                          ? '${it.productName} - ${it.variantName}\n${it.qty} x ${fmt.format(it.price)}'
                          : '${it.productName}\n${it.qty} x ${fmt.format(it.price)}',
                      style: const TextStyle(fontSize: 13))),
              Text(fmt.format(it.subtotal)),
            ],
          ),
        ));
      }
    }
    return items;
  }

  Widget _receiptRow(String l, String v,
      {bool bold = false, Color? color}) {
    final s = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        color: color);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(l, style: s), Text(v, style: s)],
    );
  }
}

class _BluetoothPickerSheet extends StatefulWidget {
  final VoidCallback onConnected;
  const _BluetoothPickerSheet({required this.onConnected});
  @override
  State<_BluetoothPickerSheet> createState() => _BluetoothPickerSheetState();
}

class _BluetoothPickerSheetState extends State<_BluetoothPickerSheet> {
  List<BluetoothDevice> _devices = [];
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    final devices = await BluetoothPrinter.scanDevices();
    setState(() {
      _devices = devices;
      _scanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Text('Pilih Printer Bluetooth',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (_scanning) const CircularProgressIndicator(strokeWidth: 2),
              if (!_scanning)
                IconButton(
                    onPressed: _scan, icon: const Icon(Icons.refresh)),
            ],
          ),
          const Divider(),
          ..._devices.map((d) => ListTile(
                leading: const Icon(Icons.print),
                title: Text(d.platformName.isEmpty ? d.remoteId.str : d.platformName),
                onTap: () async {
                  await BluetoothPrinter.connect(d);
                  widget.onConnected();
                },
              )),
          if (_devices.isEmpty && !_scanning)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tidak ada perangkat ditemukan'),
            ),
        ],
      ),
    ),
    );
  }
}

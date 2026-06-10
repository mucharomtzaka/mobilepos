import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image/image.dart' as img;
import '../models/order.dart';
import 'receipt_settings.dart';

class BluetoothPrinter {
  static const _keyDeviceId = 'printer_device_id';
  static const _keyDeviceName = 'printer_device_name';

  static BluetoothDevice? _device;
  static String? _savedDeviceId;
  static String? _savedDeviceName;

  static bool get isConnected =>
      _device != null &&
      (_device!.isConnected);

  static String? get savedDeviceId => _savedDeviceId;
  static String? get savedDeviceName => _savedDeviceName;

  /// Load saved device info from prefs
  static Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    _savedDeviceId = prefs.getString(_keyDeviceId);
    _savedDeviceName = prefs.getString(_keyDeviceName);
  }

  /// Save device to prefs
  static Future<void> _save(BluetoothDevice device) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeviceId, device.remoteId.str);
    await prefs.setString(
        _keyDeviceName,
        device.platformName.isNotEmpty
            ? device.platformName
            : device.remoteId.str);
    _savedDeviceId = device.remoteId.str;
    _savedDeviceName = device.platformName.isNotEmpty
        ? device.platformName
        : device.remoteId.str;
  }

  static Future<void> clearSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDeviceId);
    await prefs.remove(_keyDeviceName);
    _savedDeviceId = null;
    _savedDeviceName = null;
  }

  static Future<List<BluetoothDevice>> scanDevices({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    // Also include already-connected system devices
    final bonded = await FlutterBluePlus.bondedDevices;
    await FlutterBluePlus.startScan(timeout: timeout);
    final results = await FlutterBluePlus.scanResults.first;
    await FlutterBluePlus.stopScan();

    final scanned = results.map((r) => r.device).toList();
    // Merge bonded + scanned, deduplicate
    final all = {...bonded, ...scanned}.toList();
    return all;
  }

  static Future<void> connect(BluetoothDevice device) async {
    if (_device != null && _device!.remoteId == device.remoteId) {
      if (_device!.isConnected) return;
    }
    try {
      await _device?.disconnect();
    } catch (_) {}
    await device.connect(autoConnect: false);
    _device = device;
    await _save(device);
  }

  static Future<void> disconnect() async {
    await _device?.disconnect();
    _device = null;
  }

  /// Try to reconnect to saved device before printing
  static Future<bool> ensureConnected() async {
    if (isConnected) return true;
    await loadSaved();
    if (_savedDeviceId == null) return false;

    try {
      final bonded = await FlutterBluePlus.bondedDevices;
      final target = bonded.where(
          (d) => d.remoteId.str == _savedDeviceId).firstOrNull;
      if (target != null) {
        await target.connect(autoConnect: false);
        _device = target;
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> printReceipt({
    required Order order,
    required List<OrderItem> items,
    required List<PaymentEntry> payments,
    required double change,
    String cashierName = '',
    String customerName = '',
  }) async {
    if (_device == null) throw Exception('Printer tidak terhubung');

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final bytes = <int>[];
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    int _gcd(int a, int b) {
      while (b != 0) {
        final t = b;
        b = a % b;
        a = t;
      }
      return a;
    }

    bytes.addAll(generator.setGlobalCodeTable('CP1252'));

    // Logo
    final logoPath = ReceiptSettings.logoPath;
    if (logoPath != null && File(logoPath).existsSync()) {
      try {
        final raw = img.decodeImage(File(logoPath).readAsBytesSync());
        if (raw != null) {
          final resized = img.copyResize(raw, width: 200);
          bytes.addAll(generator.image(resized));
        }
      } catch (_) {}
    }

    // Store name
    bytes.addAll(generator.text(ReceiptSettings.storeName,
        styles: const PosStyles(
            align: PosAlign.center,
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2)));
    if (ReceiptSettings.address.isNotEmpty) {
      bytes.addAll(generator.text(ReceiptSettings.address,
          styles: const PosStyles(align: PosAlign.center)));
    }
    if (ReceiptSettings.phone.isNotEmpty) {
      bytes.addAll(generator.text('Telp: ${ReceiptSettings.phone}',
          styles: const PosStyles(align: PosAlign.center)));
    }
    if (ReceiptSettings.header.isNotEmpty) {
      bytes.addAll(generator.hr());
      bytes.addAll(generator.text(ReceiptSettings.header,
          styles: const PosStyles(align: PosAlign.center)));
    }
    bytes.addAll(generator.hr());
    bytes.addAll(generator.text(
        'No: ${order.orderNumber}\n${dateFmt.format(DateTime.parse(order.createdAt))}',
        styles: const PosStyles(align: PosAlign.left)));
    if (cashierName.isNotEmpty) {
      bytes.addAll(generator.text('Kasir: $cashierName',
          styles: const PosStyles(align: PosAlign.left)));
    }
    if (customerName.isNotEmpty) {
      bytes.addAll(generator.text('Pelanggan: $customerName',
          styles: const PosStyles(align: PosAlign.left)));
    }
    bytes.addAll(generator.hr());

    int i = 0;
    while (i < items.length) {
      if (items[i].bundleName != null) {
        final bundleName = items[i].bundleName!;
        final group = <OrderItem>[];
        while (i < items.length && items[i].bundleName == bundleName) {
          group.add(items[i]);
          i++;
        }
        final total = group.fold<double>(0, (s, it) => s + it.subtotal);
        final instances = group.map((it) => it.qty).reduce(_gcd);
        bytes.addAll(generator.text('[BUNDLING] $bundleName',
            styles: const PosStyles(bold: true, align: PosAlign.center)));
        for (final it in group) {
          bytes.addAll(generator.text('  ${it.qty ~/ instances}x ${it.productName}',
              styles: const PosStyles(align: PosAlign.left)));
        }
        bytes.addAll(generator.row([
          PosColumn(
              text: '${instances}x ${fmt.format(total / instances)}',
              width: 8,
              styles: const PosStyles(align: PosAlign.left)),
          PosColumn(
              text: fmt.format(total),
              width: 4,
              styles: const PosStyles(align: PosAlign.right, bold: true)),
        ]));
      } else {
        final item = items[i];
        i++;
        bytes.addAll(generator.text(item.productName,
            styles: const PosStyles(bold: true)));
        if (item.variantName != null) {
          bytes.addAll(generator.text('  ${item.variantName}',
              styles: const PosStyles(align: PosAlign.left)));
        }
        bytes.addAll(generator.row([
          PosColumn(text: '${item.qty} x ${fmt.format(item.price)}', width: 8),
          PosColumn(
              text: fmt.format(item.subtotal),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }
    }

    bytes.addAll(generator.hr());
    if (order.discountAmount > 0 || order.taxPercent > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Subtotal', width: 8),
        PosColumn(
            text: fmt.format(order.subtotal),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
      if (order.discountAmount > 0) {
        bytes.addAll(generator.row([
          PosColumn(text: 'Diskon', width: 8),
          PosColumn(
              text: '- ${fmt.format(order.discountAmount)}',
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }
      if (order.taxPercent > 0) {
        bytes.addAll(generator.row([
          PosColumn(
              text: 'Pajak ${order.taxPercent.toStringAsFixed(0)}%', width: 8),
          PosColumn(
              text: fmt.format(order.taxAmount),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]));
      }
    }
    bytes.addAll(generator.row([
      PosColumn(text: 'TOTAL', width: 8, styles: const PosStyles(bold: true)),
      PosColumn(
          text: fmt.format(order.total),
          width: 4,
          styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]));
    bytes.addAll(generator.hr());
    final totalPaid = payments.fold(0.0, (s, p) => s + p.amount);
    for (final p in payments) {
      bytes.addAll(generator.row([
        PosColumn(text: p.method.label, width: 8),
        PosColumn(
            text: fmt.format(p.amount),
            width: 4,
            styles: const PosStyles(align: PosAlign.right)),
      ]));
    }
    if (totalPaid > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Uang Dibayar', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
            text: fmt.format(totalPaid),
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]));
    }
    if (change > 0) {
      bytes.addAll(generator.row([
        PosColumn(text: 'Kembalian', width: 8, styles: const PosStyles(bold: true)),
        PosColumn(
            text: fmt.format(change),
            width: 4,
            styles: const PosStyles(align: PosAlign.right, bold: true)),
      ]));
    }
    bytes.addAll(generator.hr());
    final footerText = ReceiptSettings.footer.isNotEmpty
        ? ReceiptSettings.footer
        : 'Terima kasih!';
    bytes.addAll(generator.text(footerText,
        styles: const PosStyles(align: PosAlign.center)));
    if (ReceiptSettings.cashDrawer) {
      bytes.addAll(generator.drawer());
    }
    bytes.addAll(generator.feed(2));
    bytes.addAll(generator.cut());

    await _write(Uint8List.fromList(bytes));
  }

  static Future<void> _write(Uint8List data) async {
    if (_device == null) return;
    final services = await _device!.discoverServices();
    final mtu = _device!.mtuNow;
    for (final service in services) {
      for (final char in service.characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          final overhead = char.properties.writeWithoutResponse ? 3 : 5;
          final chunkSize = (mtu > overhead) ? (mtu - overhead) : 500;
          for (var i = 0; i < data.length; i += chunkSize) {
            final end = (i + chunkSize).clamp(0, data.length);
            await char.write(data.sublist(i, end),
                withoutResponse: char.properties.writeWithoutResponse);
          }
          return;
        }
      }
    }
    throw Exception('Tidak ada characteristic write pada printer');
  }
}

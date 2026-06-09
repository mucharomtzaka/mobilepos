import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../../../core/models/order.dart';
import '../../../core/database/order_dao.dart';

class ExcelExporter {
  static Future<File> _createExcelFile({
    required String startDate,
    required String endDate,
    required List<Order> orders,
    Directory? directory,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transaksi'];
    excel.delete('Sheet1');

    // Header
    final headers = [
      'No. Order', 'Tanggal', 'Subtotal', 'Diskon', 'Total', 'Status'
    ];
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(headers[i]);
    }

    // Data
    final fmt = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFmt = NumberFormat('#,###', 'id');
    for (var i = 0; i < orders.length; i++) {
      final o = orders[i];
      final row = i + 1;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(o.orderNumber);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(fmt.format(DateTime.parse(o.createdAt)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(currencyFmt.format(o.subtotal));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(currencyFmt.format(o.discountAmount));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = TextCellValue(currencyFmt.format(o.total));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row))
          .value = TextCellValue(o.status);
    }

    // Items sheet
    final itemSheet = excel['Item Transaksi'];
    final itemHeaders = ['No. Order', 'Produk', 'Harga', 'Qty', 'Subtotal'];
    for (var i = 0; i < itemHeaders.length; i++) {
      itemSheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .value = TextCellValue(itemHeaders[i]);
    }

    final dao = OrderDao();
    var row = 1;
    for (final o in orders) {
      final items = await dao.getItemsByOrderId(o.id!);
      for (final item in items) {
        itemSheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
            .value = TextCellValue(o.orderNumber);
        itemSheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
            .value = TextCellValue(item.productName);
        itemSheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
            .value = TextCellValue(currencyFmt.format(item.price));
        itemSheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
            .value = IntCellValue(item.qty);
        itemSheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
            .value = TextCellValue(currencyFmt.format(item.subtotal));
        row++;
      }
    }

    final bytes = excel.encode()!;
    final dir = directory ?? await getTemporaryDirectory();
    final filename =
        'laporan_${startDate}_${endDate}.xlsx'.replaceAll('-', '');
    return File('${dir.path}/$filename')..writeAsBytesSync(bytes);
  }

static Future<void> shareOrders({
    required String startDate,
    required String endDate,
    required List<Order> orders,
  }) async {
    final file = await _createExcelFile(
      startDate: startDate,
      endDate: endDate,
      orders: orders,
    );
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Laporan POS $startDate - $endDate');
  }

  static Future<String> saveToStorage({
    required String startDate,
    required String endDate,
    required List<Order> orders,
  }) async {
    // Save to public Downloads folder (Android 10+)
    final dir = await getExternalStorageDirectory();
    if (dir == null) {
      throw Exception('External storage not found');
    }
    // Navigate to /storage/emulated/0/Download
    final pathParts = dir.path.split('/');
    final emulatedIndex = pathParts.indexOf('emulated');
    if (emulatedIndex == -1) {
      throw Exception('Cannot resolve external storage path');
    }
    final basePath = pathParts.sublist(0, emulatedIndex + 2).join('/');
    final downloadsDir = Directory('$basePath/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }
    final file = await _createExcelFile(
      startDate: startDate,
      endDate: endDate,
      orders: orders,
      directory: downloadsDir,
    );
    return file.path;
  }
}

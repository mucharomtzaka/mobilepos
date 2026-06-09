import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/database/transaction_dao.dart';
import '../../../core/database/shift_dao.dart';
import '../../../core/models/transaction.dart';
import '../../shift/bloc/shift_bloc.dart';

class CashFlowPage extends StatefulWidget {
  const CashFlowPage({super.key});

  @override
  State<CashFlowPage> createState() => _CashFlowPageState();
}

class _CashFlowPageState extends State<CashFlowPage> {
  final _dao = TransactionDao();
  final _shiftDao = ShiftDao();
  List<Transaction> _list = [];
  bool _loading = true;

  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  bool _shiftFilter = false;

  double _totalIncome = 0;
  double _totalExpense = 0;
  double _openingCash = 0;
  double _closingCash = 0;
  bool _allShiftsClosed = false;
  List<Map<String, dynamic>> _incomeCategories = [];
  List<Map<String, dynamic>> _expenseCategories = [];

  @override
  void initState() {
    super.initState();
    final shiftState = context.read<ShiftBloc>().state;
    if (shiftState is ShiftOpen) {
      _startDate = DateTime.parse(shiftState.shift.startTime);
      _shiftFilter = true;
    }
    _load();
  }

  String get _startStr =>
      DateFormat('yyyy-MM-dd').format(_startDate);
  String get _endStr =>
      DateFormat('yyyy-MM-dd').format(_endDate);

  Future<void> _load() async {
    setState(() => _loading = true);

    final start = '${_startStr}T00:00:00';
    final end = '${_endStr}T23:59:59';

    final results = await Future.wait([
      _dao.getByDateRange(start, end),
      _dao.getTotalByDateRange(start, end, type: 'income'),
      _dao.getTotalByDateRange(start, end, type: 'expense'),
      _dao.getCategorySummary(start, end, type: 'income'),
      _dao.getCategorySummary(start, end, type: 'expense'),
      _shiftDao.getTotalOpeningCash(startDate: start, endDate: end),
      _shiftDao.getTotalClosingCash(startDate: start, endDate: end),
      _shiftDao.hasOpenShift(startDate: start, endDate: end),
    ]);

    if (mounted) {
      setState(() {
        _list = results[0] as List<Transaction>;
        _totalIncome = results[1] as double;
        _totalExpense = results[2] as double;
        _incomeCategories = results[3] as List<Map<String, dynamic>>;
        _expenseCategories = results[4] as List<Map<String, dynamic>>;
        _openingCash = results[5] as double;
        _closingCash = results[6] as double;
        _allShiftsClosed = !(results[7] as bool);
        _loading = false;
      });
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      locale: const Locale('id', 'ID'),
    );
    if (picked != null) {
      setState(() { _startDate = picked.start; _endDate = picked.end; });
      _load();
    }
  }

  Future<void> _exportExcel() async {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final excel = Excel.createExcel();
    final sheet = excel['Arus Kas'];
    excel.delete('Sheet1');

    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = TextCellValue('LAPORAN ARUS KAS');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 1))
        .value = TextCellValue(
            'Periode: ${dateFmt.format(_startDate)} - ${dateFmt.format(_endDate)}');

    final headers = ['Tanggal', 'Tipe', 'Kategori', 'Keterangan', 'Jumlah'];
    for (var c = 0; c < headers.length; c++) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: c, rowIndex: 3))
          .value = TextCellValue(headers[c]);
    }

    var row = 4;
    for (final t in _list) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue(dateFmt.format(DateTime.parse(t.createdAt)));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row))
          .value = TextCellValue(t.type == 'income' ? 'Pemasukan' : 'Pengeluaran');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row))
          .value = TextCellValue(t.category);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row))
          .value = TextCellValue(t.description ?? '');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(t.amount);
      row++;
    }

    row += 2;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('MODAL AWAL SHIFT');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = DoubleCellValue(_openingCash);
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('TOTAL PEMASUKAN');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = DoubleCellValue(_totalIncome);
    row++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('TOTAL PENGELUARAN');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = DoubleCellValue(_totalExpense);
    row++;
    final excelTeori = _openingCash + _totalIncome - _totalExpense;
    final excelAktual = _allShiftsClosed ? _closingCash : excelTeori;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
        .value = TextCellValue('SALDO DI LACI');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
        .value = DoubleCellValue(excelAktual);
    if (_allShiftsClosed) {
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('TEORI');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(excelTeori);
      row++;
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row))
          .value = TextCellValue('SELISIH');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row))
          .value = DoubleCellValue(excelAktual - excelTeori);
    }

    final bytes = excel.encode()!;
    final dir = await getTemporaryDirectory();
    final filename =
        'arus_kas_${_startStr}_${_endStr}.xlsx'.replaceAll('-', '');
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)],
        subject: 'Laporan Arus Kas $filename');
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy');
    final netCash = _totalIncome - _totalExpense;
    final teoretis = _openingCash + _totalIncome - _totalExpense;
    final saldoLaci = _allShiftsClosed ? _closingCash : teoretis;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Arus Kas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Pilih Periode',
            onPressed: _pickDateRange,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Download Excel',
            onPressed: _list.isEmpty ? null : _exportExcel,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isTablet = constraints.maxWidth > 800;
          final horizontalPadding = isTablet ? 48.0 : 16.0;
          
          if (_loading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 16,
              ),
              children: [
                // Period
                Center(
                  child: GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.date_range, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${dateFmt.format(_startDate)} - ${dateFmt.format(_endDate)}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (_shiftFilter) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Shift Aktif',
                                  style: TextStyle(fontSize: 10, color: Colors.orange)),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Summary cards
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        'Pemasukan',
                        fmt.format(_totalIncome),
                        Colors.green,
                        Icons.trending_up,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _summaryCard(
                        'Pengeluaran',
                        fmt.format(_totalExpense),
                        Colors.red,
                        Icons.trending_down,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _summaryCard(
                  'Saldo Bersih',
                  fmt.format(netCash),
                  netCash >= 0 ? Colors.blue : Colors.orange,
                  netCash >= 0 ? Icons.account_balance : Icons.warning,
                  fullWidth: true,
                ),
                const SizedBox(height: 12),
                _summaryCard(
                  _allShiftsClosed ? 'Saldo di Laci (Aktual)' : 'Saldo di Laci',
                  fmt.format(saldoLaci),
                  Colors.teal,
                  Icons.point_of_sale,
                  fullWidth: true,
                  large: true,
                ),
                if (_allShiftsClosed && teoretis != _closingCash)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Teori: ${fmt.format(teoretis)}  |  Selisih: ${fmt.format(saldoLaci - teoretis)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                const SizedBox(height: 24),

                // Income categories
                if (_incomeCategories.isNotEmpty) ...[
                  const Text('Pemasukan per Kategori',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _incomeCategories.map((c) {
                        final pct = _totalIncome > 0
                            ? ((c['total'] as num).toDouble() / _totalIncome * 100)
                            : 0.0;
                        return ListTile(
                          dense: true,
                          title: Text(c['category'] as String),
                          trailing: Text(fmt.format((c['total'] as num).toDouble()),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${pct.toStringAsFixed(1)}% • ${c['count']} transaksi'),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Expense categories
                if (_expenseCategories.isNotEmpty) ...[
                  const Text('Pengeluaran per Kategori',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: _expenseCategories.map((c) {
                        final pct = _totalExpense > 0
                            ? ((c['total'] as num).toDouble() / _totalExpense * 100)
                            : 0.0;
                        return ListTile(
                          dense: true,
                          title: Text(c['category'] as String),
                          trailing: Text(fmt.format((c['total'] as num).toDouble()),
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('${pct.toStringAsFixed(1)}% • ${c['count']} transaksi'),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // All transactions
                const Text('Semua Transaksi',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                if (_list.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_balance_wallet, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(height: 8),
                        Text('Tidak ada transaksi di periode ini', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  )
                else
                  ..._list.map((t) {
                    final isIncome = t.type == 'income';
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 3),
                      child: ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: (isIncome ? Colors.green : Colors.red)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            isIncome
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: isIncome ? Colors.green : Colors.red,
                            size: 18,
                          ),
                        ),
                        title: Text(t.category,
                            style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          '${t.description ?? ''}${t.description != null ? ' • ' : ''}${dateFmt.format(DateTime.parse(t.createdAt))}',
                          style: const TextStyle(fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          fmt.format(t.amount),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        dense: true,
                      ),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color, IconData icon,
      {bool fullWidth = false, bool large = false}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(fullWidth ? (large ? 24 : 20) : 16),
        child: fullWidth
            ? Row(
                children: [
                  Icon(icon, size: large ? 36 : 28, color: color),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                              color: Colors.grey[600], fontSize: large ? 15 : 13)),
                      Text(value,
                          style: TextStyle(
                              fontSize: large ? 24 : 18,
                              fontWeight: FontWeight.bold,
                              color: color)),
                    ],
                  ),
                ],
              )
            : Column(
                children: [
                  Icon(icon, size: large ? 36 : 28, color: color),
                  const SizedBox(height: 8),
                  Text(title,
                      style:
                          TextStyle(color: Colors.grey[600], fontSize: large ? 14 : 12)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: TextStyle(
                          fontSize: large ? 22 : 16,
                          fontWeight: FontWeight.bold,
                          color: color),
                      textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }
}
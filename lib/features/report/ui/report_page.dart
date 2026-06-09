import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/report_bloc.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/utils/excel_exporter.dart' show ExcelExporter;
import '../../payment/ui/receipt_page.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ReportBloc(OrderDao()),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatefulWidget {
  const _ReportView();
  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  late DateTime _start;
  late DateTime _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _start = DateTime(now.year, now.month, 1);
    _end = now;
    _load();
  }

  void _load() {
    context.read<ReportBloc>().add(ReportLoad(
          startDate: _fmt(_start),
          endDate: _fmt(_end),
        ));
  }

  String _fmt(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _start : _end,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && mounted) {
      setState(() => isStart ? _start = picked : _end = picked);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          BlocBuilder<ReportBloc, ReportState>(
            builder: (ctx, state) => state is ReportLoaded
                ? PopupMenuButton<String>(
                    icon: const Icon(Icons.download),
                    tooltip: 'Export Excel',
                    onSelected: (value) async {
                      if (value == 'share') {
                        await ExcelExporter.shareOrders(
                          startDate: state.startDate,
                          endDate: state.endDate,
                          orders: state.orders,
                        );
                      } else if (value == 'save') {
                        final path = await ExcelExporter.saveToStorage(
                          startDate: state.startDate,
                          endDate: state.endDate,
                          orders: state.orders,
                        );
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text('Disimpan: $path'),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'share',
                        child: Row(
                          children: [
                            Icon(Icons.share),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'save',
                        child: Row(
                          children: [
                            Icon(Icons.save),
                            SizedBox(width: 8),
                            Text('Simpan'),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd/MM/yy').format(_start)),
                    onPressed: () => _pickDate(true),
                  ),
                ),
                const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text('s/d')),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(DateFormat('dd/MM/yy').format(_end)),
                    onPressed: () => _pickDate(false),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ReportBloc, ReportState>(
              builder: (ctx, state) {
                if (state is ReportLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ReportLoaded) {
                  return LayoutBuilder(
                    builder: (_, constraints) {
                      if (constraints.maxWidth > 800) {
                        return _buildTabletLayout(ctx, state, fmt);
                      }
                      return _buildPhoneLayout(ctx, state, fmt);
                    },
                  );
                }
                return const Center(child: Text('Memuat laporan...'));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneLayout(BuildContext ctx, ReportLoaded state, NumberFormat fmt) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._buildSummarySection(state, fmt),
        ..._buildAnalyticsSection(ctx, state, fmt),
        ..._buildPaymentAndProductsSection(state, fmt),
        _buildTransactionList(ctx, state, fmt),
        const Divider(height: 24),
        _buildItemSalesSection(ctx, state, fmt),
      ],
    );
  }

  Widget _buildTabletLayout(BuildContext ctx, ReportLoaded state, NumberFormat fmt) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
            children: [
              ..._buildSummarySection(state, fmt),
              ..._buildAnalyticsSection(ctx, state, fmt),
              ..._buildPaymentAndProductsSection(state, fmt),
              const Divider(height: 24),
              _buildItemSalesSection(ctx, state, fmt),
            ],
          ),
        ),
        Container(width: 1, color: Colors.grey[300]),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 16, 16, 16),
            children: [
              _buildTransactionList(ctx, state, fmt),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSummarySection(ReportLoaded state, NumberFormat fmt) {
    return [
      Row(children: [
        _card('Total Transaksi', '${state.totalOrders}',
            Icons.receipt, Colors.blue),
        const SizedBox(width: 8),
        _card('Total Penjualan',
            fmt.format(state.totalRevenue),
            Icons.attach_money, Colors.green),
      ]),
      const SizedBox(height: 8),
      Row(children: [
        _card('Total Diskon',
            fmt.format(state.totalDiscount),
            Icons.discount, Colors.orange),
        const SizedBox(width: 8),
        _card(
          'Rata-rata/Transaksi',
          state.totalOrders > 0
              ? fmt.format(state.totalRevenue / state.totalOrders)
              : 'Rp 0',
          Icons.bar_chart,
          Colors.purple,
        ),
      ]),
    ];
  }

  List<Widget> _buildAnalyticsSection(BuildContext ctx, ReportLoaded state, NumberFormat fmt) {
    if (state.comparison.isEmpty) return [];
    return [
      const SizedBox(height: 8),
      const Text('Analitik',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      const SizedBox(height: 8),
      Row(children: [
        _cardGrowth(
          'Transaksi',
          (state.comparison['currentOrders'] as num?)?.toDouble() ?? 0.0,
          (state.comparison['ordersGrowth'] as num?)?.toDouble() ?? 0.0,
          Icons.receipt_long,
        ),
        const SizedBox(width: 8),
        _cardGrowth(
          'Pendapatan',
          (state.comparison['currentRevenue'] as num?)?.toDouble() ?? 0.0,
          (state.comparison['revenueGrowth'] as num?)?.toDouble() ?? 0.0,
          Icons.trending_up,
        ),
      ]),
      const SizedBox(height: 8),
      if (state.dailySales.isNotEmpty) ...[
        const Text('Penjualan Harian',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 120,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: state.dailySales.isEmpty
                ? []
                : (() {
                    final sales = state.dailySales.take(14).toList();
                    final revenues = sales.map((d) => (d['revenue'] as num?)?.toDouble() ?? 0.0).toList();
                    final maxRevenue = revenues.isEmpty ? 0.0 : revenues.reduce((a, b) => a > b ? a : b);
                    return sales.map((d) {
                      final revenue = (d['revenue'] as num?)?.toDouble() ?? 0.0;
                      final height = maxRevenue > 0
                          ? (revenue / maxRevenue * 80).clamp(4.0, 80.0)
                          : 4.0;
                      return Expanded(
                        child: Tooltip(
                          message: '${d['date']}: ${fmt.format(revenue)}',
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            height: height,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }).toList();
                  })(),
          ),
        ),
        const SizedBox(height: 4),
        Text('${state.dailySales.length} hari',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
      const SizedBox(height: 8),
      if (state.hourlySales.isNotEmpty) ...[
        const Text('Penjualan per Jam',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: state.hourlySales.map((h) {
            final hour = int.parse(h['hour'] as String);
            final orders = (h['orders'] as int?) ?? 0;
            final label = '$hour:00';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: orders > 0
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text('$label ($orders)',
                  style: TextStyle(
                      fontSize: 10,
                      color: orders > 0
                          ? Theme.of(context).primaryColor
                          : Colors.grey)),
            );
          }).toList(),
        ),
      ],
      const SizedBox(height: 16),
    ];
  }

  List<Widget> _buildPaymentAndProductsSection(ReportLoaded state, NumberFormat fmt) {
    return [
      if (state.paymentSummary.isNotEmpty) ...[
        const Text('Ringkasan Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...state.paymentSummary.map((p) => ListTile(
              dense: true,
              leading: const Icon(Icons.payment),
              title: Text(p['method'] as String),
              trailing: Text(fmt.format((p['total'] as num).toDouble())),
            )),
        const Divider(),
      ],
      if (state.topProducts.isNotEmpty) ...[
        const Text('Produk Terlaris',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ...state.topProducts.asMap().entries.map((e) => ListTile(
              dense: true,
              leading: CircleAvatar(
                  radius: 14,
                  child: Text('${e.key + 1}',
                      style: const TextStyle(fontSize: 12))),
              title: Text(e.value['product_name'] as String),
              subtitle: Text('Terjual: ${e.value['total_qty']}'),
              trailing: Text(fmt.format((e.value['total_revenue'] as num).toDouble())),
            )),
        const Divider(),
      ],
    ];
  }

  Widget _buildTransactionList(BuildContext ctx, ReportLoaded state, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Daftar Transaksi',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        if (state.orders.isEmpty)
          const Center(
            child: _EmptyState(
              icon: Icons.receipt_long,
              message: 'Belum ada transaksi',
            ),
          )
        else
          ...state.orders.map((o) {
            final isCancelled = o.status == 'cancelled';
            return ListTile(
              dense: true,
              leading: Icon(
                isCancelled ? Icons.cancel : Icons.receipt_long,
                color: isCancelled ? Colors.red : Colors.blue,
              ),
              title: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  Text(o.orderNumber),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isCancelled ? Colors.red.shade100 : Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isCancelled ? 'DIBATALKAN' : 'BERHASIL',
                      style: TextStyle(
                        fontSize: 10,
                        color: isCancelled ? Colors.red.shade700 : Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(DateFormat('dd/MM/yy HH:mm')
                  .format(DateTime.parse(o.createdAt))),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fmt.format(o.total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCancelled ? Colors.red : null,
                        decoration: isCancelled ? TextDecoration.lineThrough : null,
                      )),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
              onTap: () => Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => ReceiptPage(order: o, change: o.change),
                ),
              ),
            );
          }),
        if (state.hasMoreOrders)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.expand_more),
                label: Text('Muat Lagi (${state.orders.length}/${state.ordersTotal})'),
                onPressed: () => ctx.read<ReportBloc>().add(ReportLoadMoreOrders()),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildItemSalesSection(BuildContext ctx, ReportLoaded state, NumberFormat fmt) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Penjualan Per Item',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        if (state.itemSales.isEmpty)
          const _EmptyState(
            icon: Icons.inventory_2,
            message: 'Belum ada penjualan per item',
          )
        else
          Column(
            children: state.itemSales.take(20).toList().asMap().entries.map((e) => _ItemSalesCard(
              no: e.key + 1,
              productName: e.value['product_name'] as String,
              variantName: e.value['variant_name'] as String?,
              qty: (e.value['qty'] as num).toInt(),
              price: (e.value['price'] as num).toDouble(),
              subtotal: (e.value['subtotal'] as num).toDouble(),
              date: e.value['created_at'] as String,
              fmt: fmt,
            )).toList(),
          ),
        if (state.hasMoreItems)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: TextButton.icon(
                icon: const Icon(Icons.expand_more),
                label: Text('Muat Lagi (${state.itemSales.length}/${state.itemSalesTotal})'),
                onPressed: () => ctx.read<ReportBloc>().add(ReportLoadMoreItems()),
              ),
            ),
          ),
        if (state.itemSales.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Item: ${state.itemSales.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Total Penjualan: ${fmt.format(state.itemSales.fold(0.0, (sum, item) => sum + (item['subtotal'] as num).toDouble()))}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Theme.of(context).primaryColor)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _card(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cardGrowth(String label, num value, num growth, IconData icon) {
    final isPositive = growth >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final formatted = label == 'Transaksi' ? '${value.toInt()}' : fmt.format(value.toDouble());
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
              Text(formatted,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 12,
                    color: color,
                  ),
                  Text(
                    '${growth.abs().toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemSalesCard extends StatelessWidget {
  final int no;
  final String productName;
  final String? variantName;
  final int qty;
  final double price;
  final double subtotal;
  final String date;
  final NumberFormat fmt;

  const _ItemSalesCard({
    required this.no,
    required this.productName,
    this.variantName,
    required this.qty,
    required this.price,
    required this.subtotal,
    required this.date,
    required this.fmt,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // No
            SizedBox(
              width: 28,
              child: Text(
                '$no',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    productName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (variantName != null && variantName!.isNotEmpty)
                    Text(
                      variantName!,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.parse(date)),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            // Qty & Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'x$qty',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  fmt.format(price),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            // Subtotal
            SizedBox(
              width: 80,
              child: Text(
                fmt.format(subtotal),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

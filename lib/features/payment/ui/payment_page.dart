import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/payment_bloc.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../../core/models/order.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shift/bloc/shift_bloc.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/database/stock_dao.dart';
import '../../../core/api/sync_service.dart';
import 'receipt_page.dart';

class PaymentPage extends StatelessWidget {
  const PaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PaymentBloc(OrderDao(), StockDao()),
      child: const _PaymentView(),
    );
  }
}

class _PaymentView extends StatefulWidget {
  const _PaymentView();
  @override
  State<_PaymentView> createState() => _PaymentViewState();
}

class _PaymentViewState extends State<_PaymentView> {
  PaymentMethod _selectedMethod = PaymentMethod.tunai;
  final _amountCtrl = TextEditingController();
  late final NumberFormat _amountFmt;
  double? _selectedAmount;

  @override
  void initState() {
    super.initState();
    _amountFmt = NumberFormat('#,###', 'id_ID');
    _amountCtrl.addListener(_formatAmount);
  }

  @override
  void dispose() {
    _amountCtrl.removeListener(_formatAmount);
    _amountCtrl.dispose();
    super.dispose();
  }

  void _formatAmount() {
    final text = _amountCtrl.text.replaceAll('.', '');
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    final formatted = _amountFmt.format(parsed);
    if (_amountCtrl.text != formatted) {
      _amountCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  void _addEntry(BuildContext ctx, double remaining) {
    final amount =
        double.tryParse(_amountCtrl.text.replaceAll('.', '')) ?? remaining;
    ctx.read<PaymentBloc>().add(
          PaymentAddEntry(
            PaymentEntry(method: _selectedMethod, amount: amount),
          ),
        );
    _amountCtrl.clear();
  }

  void _addTransferWithReference(BuildContext ctx, double remaining) {
    final nameCtrl = TextEditingController();
    final accCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Referensi Transfer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Pengirim',
                hintText: 'Cth: Budi Santoso',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: accCtrl,
              decoration: const InputDecoration(
                labelText: 'No Rekening',
                hintText: 'Cth: 1234567890',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameCtrl.dispose();
              accCtrl.dispose();
              Navigator.pop(dCtx);
            },
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final parts = <String>[];
              if (nameCtrl.text.trim().isNotEmpty) {
                parts.add(nameCtrl.text.trim());
              }
              if (accCtrl.text.trim().isNotEmpty) {
                parts.add(accCtrl.text.trim());
              }
              final ref = parts.isNotEmpty ? parts.join(' - ') : null;
              ctx.read<PaymentBloc>().add(
                    PaymentAddEntry(
                      PaymentEntry(
                        method: PaymentMethod.transfer,
                        amount: remaining,
                        reference: ref,
                      ),
                    ),
                  );
              nameCtrl.dispose();
              accCtrl.dispose();
              Navigator.pop(dCtx);
            },
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext ctx) {
    final cartState = ctx.read<CartBloc>().state;
    final authState = ctx.read<AuthBloc>().state;
    final shiftState = ctx.read<ShiftBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final payState = ctx.read<PaymentBloc>().state;
    if (payState is! PaymentIdle) return;

    if (payState.totalPaid < cartState.total) {
      ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Jumlah pembayaran kurang')));
      return;
    }

    ctx.read<PaymentBloc>().add(PaymentConfirm(
          cartState: cartState,
          userId: authState.user.id!,
          shiftId: shiftState is ShiftOpen ? shiftState.shift.id : null,
          customerId: cartState.customer?.id,
          tableId: cartState.table?.id,
          note: cartState.note,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: BlocConsumer<PaymentBloc, PaymentState>(
        listener: (ctx, state) {
          if (state is PaymentSuccess) {
            ctx.read<CartBloc>().add(CartClear());
            ctx.read<PaymentBloc>().add(PaymentReset());
            SyncService.instance.syncAll();
            Navigator.pushReplacement(
              ctx,
              MaterialPageRoute(
                  builder: (_) =>
                      ReceiptPage(order: state.order, change: state.change)),
            );
          } else if (state is PaymentFailure) {
            ScaffoldMessenger.of(ctx)
                .showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (ctx, state) {
          final cartState = ctx.watch<CartBloc>().state;
          final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
          final entries =
              state is PaymentIdle ? state.entries : <PaymentEntry>[];
          final totalPaid =
              state is PaymentIdle ? state.totalPaid : 0.0;
          final remaining = cartState.total - totalPaid;

          return LayoutBuilder(
            builder: (_, constraints) {
              if (constraints.maxWidth > 800) {
                return _buildTabletLayout(ctx, state, cartState, fmt, entries, totalPaid, remaining);
              }
              return _buildPhoneLayout(ctx, state, cartState, fmt, entries, totalPaid, remaining);
            },
          );
        },
      ),
    );
  }

  Widget _buildPhoneLayout(
    BuildContext ctx,
    PaymentState state,
    CartState cartState,
    NumberFormat fmt,
    List<PaymentEntry> entries,
    double totalPaid,
    double remaining,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(cartState, fmt, totalPaid, remaining),
        const SizedBox(height: 16),
        ...entries.asMap().entries.map((e) => ListTile(
              leading: const Icon(Icons.payment),
              title: Text(e.value.method.label),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(fmt.format(e.value.amount)),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => ctx
                        .read<PaymentBloc>()
                        .add(PaymentRemoveEntry(e.key)),
                  ),
                ],
              ),
            )),
        const Divider(),
        if (remaining > 0) _buildPaymentInput(ctx, fmt, remaining),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (state is PaymentProcessing || remaining > 0)
                ? null
                : () => _confirm(ctx),
            child: state is PaymentProcessing
                ? const CircularProgressIndicator()
                : const Text('Konfirmasi Pembayaran'),
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout(
    BuildContext ctx,
    PaymentState state,
    CartState cartState,
    NumberFormat fmt,
    List<PaymentEntry> entries,
    double totalPaid,
    double remaining,
  ) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column: summary + entries
            Expanded(
              flex: 2,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
                children: [
                  _buildSummaryCard(cartState, fmt, totalPaid, remaining),
                  const SizedBox(height: 16),
                  ...entries.asMap().entries.map((e) => ListTile(
                        dense: true,
                        leading: const Icon(Icons.payment, size: 20),
                        title: Text(e.value.method.label, style: const TextStyle(fontSize: 13)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(fmt.format(e.value.amount), style: const TextStyle(fontSize: 13)),
                            IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => ctx
                                  .read<PaymentBloc>()
                                  .add(PaymentRemoveEntry(e.key)),
                            ),
                          ],
                        ),
                      )),
                  if (remaining > 0 && entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                            child: _buildPaymentMethodSelector(ctx, remaining),
                    ),
                ],
              ),
            ),
            Container(width: 1, color: Colors.grey[300]),
            // Right column: numpad
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  // Amount display + action buttons
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 16, 16, 12),
                    child: Column(
                      children: [
                        // Amount display
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text('Rp ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              Expanded(
                                child: ListenableBuilder(
                                  listenable: _amountCtrl,
                                  builder: (_, __) => Text(
                                    _amountCtrl.text.isEmpty
                                        ? NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(remaining)
                                        : _amountCtrl.text,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (remaining > 0 && entries.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                      child: _buildPaymentMethodSelector(ctx, remaining),
                          ),
                        const SizedBox(height: 8),
                        // Action buttons
                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Tambah', style: TextStyle(fontSize: 13)),
                                  onPressed: remaining <= 0
                                      ? null
                                      : () => _addEntry(ctx, remaining),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: SizedBox(
                                height: 40,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle, size: 16),
                                  label: const Text('Bayar', style: TextStyle(fontSize: 13)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(ctx).primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  onPressed: (state is PaymentProcessing || remaining > 0)
                                      ? null
                                      : () => _confirm(ctx),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (state is PaymentProcessing)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: LinearProgressIndicator(),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  // Numpad
                  Expanded(
                    child: _Numpad(
                      controller: _amountCtrl,
                      onEnter: remaining > 0 ? () => _addEntry(ctx, remaining) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    CartState cartState,
    NumberFormat fmt,
    double totalPaid,
    double remaining,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _row('Subtotal', fmt.format(cartState.subtotal)),
            if (cartState.discountAmount > 0)
              _row('Diskon', '- ${fmt.format(cartState.discountAmount)}',
                  color: Colors.green),
            if (cartState.taxPercent > 0)
              _row('Pajak ${cartState.taxPercent.toStringAsFixed(0)}%',
                  fmt.format(cartState.taxAmount),
                  color: Colors.blue),
            const Divider(),
            _row('Total', fmt.format(cartState.total),
                bold: true, large: true),
            _row('Sudah Dibayar', fmt.format(totalPaid),
                color: Colors.blue),
            if (remaining < 0)
              _row(
                'Kembalian',
                fmt.format(-remaining),
                color: Colors.green,
                bold: true,
              )
            else
              _row(
                'Sisa',
                fmt.format(remaining),
                color: remaining <= 0 ? Colors.green : Colors.red,
                bold: true,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector(BuildContext ctx, double remaining) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        children: PaymentMethod.values
            .map((m) => ChoiceChip(
                  label: Text(m.label),
                  selected: _selectedMethod == m,
                  onSelected: (_) {
                    setState(() => _selectedMethod = m);
                    if (m != PaymentMethod.tunai && remaining > 0) {
                      if (m == PaymentMethod.transfer) {
                        _addTransferWithReference(ctx, remaining);
                      } else {
                        _addEntry(ctx, remaining);
                      }
                    }
                  },
                ))
            .toList(),
      ),
    );
  }

  Widget _buildPaymentInput(BuildContext ctx, NumberFormat fmt, double remaining) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tambah Pembayaran',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildPaymentMethodSelector(ctx, remaining),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Jumlah',
                  hintText: fmt.format(remaining),
                  border: const OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            if (_selectedMethod == PaymentMethod.tunai)
              ElevatedButton(
                onPressed: () => _addEntry(ctx, remaining),
                child: const Text('Tambah'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_selectedMethod == PaymentMethod.tunai)
          Wrap(
            spacing: 8,
            children: _quickAmounts(remaining)
                .map((a) => ChoiceChip(
                      label: Text(fmt.format(a)),
                      selected: _selectedAmount == a,
                      onSelected: (_) {
                        _amountCtrl.text = a.toStringAsFixed(0);
                        _addEntry(ctx, remaining);
                      },
                    ))
                .toList(),
          ),
      ],
    );
  }

  List<double> _quickAmounts(double remaining) {
    final bills = [5000, 10000, 20000, 50000, 100000, 200000];
    return bills
        .map((b) => b.toDouble())
        .where((b) => b > remaining)
        .take(4)
        .toList()
      ..insert(0, remaining);
  }

  Widget _row(String label, String value,
      {bool bold = false, bool large = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: large ? 18 : 14,
      color: color,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback? onEnter;

  const _Numpad({required this.controller, this.onEnter});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final row in [
            ['7', '8', '9'],
            ['4', '5', '6'],
            ['1', '2', '3'],
          ])
            Expanded(
              child: Row(
                children: row.map((d) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumpadButton(
                      label: d,
                      onTap: () {
                        final text = controller.text;
                        final sel = controller.selection;
                        final newText = '${text.substring(0, sel.start)}$d${text.substring(sel.end)}';
                        controller.text = newText;
                        controller.selection = TextSelection.collapsed(offset: sel.start + 1);
                      },
                    ),
                  ),
                )).toList(),
              ),
            ),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumpadButton(
                      label: '0',
                      onTap: () {
                        final text = controller.text;
                        final sel = controller.selection;
                        final newText = '${text.substring(0, sel.start)}0${text.substring(sel.end)}';
                        controller.text = newText;
                        controller.selection = TextSelection.collapsed(offset: sel.start + 1);
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumpadButton(
                      label: 'C',
                      color: Colors.red.shade100,
                      onTap: () {
                        controller.clear();
                      },
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _NumpadButton(
                      label: '↵',
                      color: Colors.green,
                      onTap: onEnter ?? () {},
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final Color? color;
  final VoidCallback onTap;
  final VoidCallback? longPress;

  const _NumpadButton({
    required this.label,
    this.color,
    required this.onTap,
    this.longPress,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: color ?? Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            onLongPress: longPress,
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

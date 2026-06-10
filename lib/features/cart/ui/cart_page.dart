import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../bloc/cart_bloc.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/order.dart';
import '../../../core/models/table.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/database/customer_dao.dart';
import '../../../core/database/table_dao.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../shift/bloc/shift_bloc.dart';
import '../../payment/ui/payment_page.dart';
import '../../../core/utils/responsive_dialog.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../../core/utils/bluetooth_printer.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  int _draftCountKey = 0;

  void _refreshDraftCount() {
    setState(() {
      _draftCountKey = DateTime.now().millisecondsSinceEpoch;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keranjang'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (ctx, state) => state.items.isEmpty
                ? const SizedBox()
                : Container(
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.delete_sweep),
                      tooltip: 'Kosongkan',
                      onPressed: () => ctx.read<CartBloc>().add(CartClear()),
                    ),
                  ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: FutureBuilder<int>(
              key: ValueKey(_draftCountKey),
              future: OrderDao().getDraftOrders().then((l) => l.length),
              builder: (_, snap) {
                final count = snap.data ?? 0;
                return Badge(
                  isLabelVisible: count > 0,
                  label: Text('$count'),
                  child: IconButton(
                    icon: const Icon(Icons.inbox),
                    tooltip: 'Ambil Draft',
                    onPressed: () => _pickupDraft(context),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () => _scanBarcode(context),
            ),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (ctx, constraints) {
          final isKeyboard = MediaQuery.of(ctx).viewInsets.bottom > 0;
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CustomerBar(),
                _TableBar(),
                _NoteBar(),
                const Divider(height: 1),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: 100,
                    maxHeight: constraints.maxHeight * 0.35,
                  ),
                  child: _CartItemList(),
                ),
                _DiscountBar(),
                _CartSummary(onDraftSaved: _refreshDraftCount),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<bool> _requestCameraPermission(BuildContext ctx) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;
    if (status.isPermanentlyDenied) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            content: const Text(
                'Izin kamera ditolak permanen. Izinkan di pengaturan aplikasi.'),
            action: SnackBarAction(
              label: 'Buka Pengaturan',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
      return false;
    }
    final result = await Permission.camera.request();
    if (!result.isGranted) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Izin kamera ditolak')),
        );
      }
      return false;
    }
    return true;
  }

  void _pickupDraft(BuildContext ctx) async {
    final dao = OrderDao();
    final drafts = await dao.getDraftOrders();
    if (!ctx.mounted) return;
    if (drafts.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Tidak ada draft')),
      );
      return;
    }
    showConstrainedModalBottomSheet(
      context: ctx,
      builder: (_) => _DraftPickerSheet(
        dao: dao,
        drafts: drafts,
        onPicked: (order, items) {
          ctx.read<CartBloc>().add(CartLoadDraft(order: order, items: items));
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Draft ${order.orderNumber} dimuat')),
          );
        },
        onDeleted: () {
          _refreshDraftCount();
        },
        onDraftDeleted: _refreshDraftCount,
      ),
    );
  }

  void _scanBarcode(BuildContext ctx) async {
    if (!await _requestCameraPermission(ctx)) return;
    if (!ctx.mounted) return;
    Navigator.push(
      ctx,
      MaterialPageRoute(builder: (_) => BarcodeScanPage(cartContext: ctx)),
    );
  }
}

class _CartItemList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, state) {
        if (state.items.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.shopping_cart_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                Text('Keranjang kosong',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          );
        }
        return ListView(children: _buildItemList(ctx, state.items));
      },
    );
  }

  List<Widget> _buildItemList(BuildContext ctx, List<CartItem> items) {
    final list = <Widget>[];
    int i = 0;
    while (i < items.length) {
      if (items[i].bundleId != null) {
        final bundleId = items[i].bundleId;
        final bundleName = items[i].bundleName!;
        final group = <CartItem>[];
        while (i < items.length && items[i].bundleId == bundleId) {
          group.add(items[i]);
          i++;
        }
        final instances = group.map((i) => i.qty).reduce(_gcd);
        list.add(_BundleGroupHeader(
            bundleName: bundleName, group: group, instances: instances));
        for (final item in group) {
          list.add(_BundleItemRow(item: item, instances: instances));
        }
        list.add(_BundleGroupTotal(group: group, instances: instances));
      } else {
        list.add(_CartItemTile(item: items[i]));
        i++;
      }
    }
    return list;
  }
}

class _BundleGroupHeader extends StatelessWidget {
  final String bundleName;
  final List<CartItem> group;
  final int instances;
  const _BundleGroupHeader(
      {required this.bundleName, required this.group, required this.instances});

  @override
  Widget build(BuildContext context) {
    final total = group.fold<double>(0, (s, i) => s + i.subtotal);
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.orange, width: 2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.redeem, size: 16, color: Colors.orange),
          const SizedBox(width: 6),
          Expanded(
            child: Text(bundleName,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}

class _BundleItemRow extends StatelessWidget {
  final CartItem item;
  final int instances;
  const _BundleItemRow({required this.item, required this.instances});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 22),
          Text('${item.qty ~/ instances}x ',
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(
            child: Text(item.product.name,
                style: const TextStyle(fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _BundleGroupTotal extends StatelessWidget {
  final List<CartItem> group;
  final int instances;
  const _BundleGroupTotal({required this.group, required this.instances});

  @override
  Widget build(BuildContext context) {
    final totalBundle = group.fold<double>(0, (s, i) => s + i.subtotal);
    final bundlePrice = totalBundle / instances;
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.orange.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text('${instances}x ${fmt.format(bundlePrice)}',
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          const Divider(height: 12),
          Row(
            children: [
              const Spacer(),
              Text(fmt.format(totalBundle),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ],
      ),
    );
  }
}

int _gcd(int a, int b) {
  while (b != 0) {
    final t = b;
    b = a % b;
    a = t;
  }
  return a;
}

class _CustomerBar extends StatelessWidget {
  void _showPicker(BuildContext ctx) {
    showConstrainedModalBottomSheet(
      context: ctx,
      builder: (_) => _CustomerPickerSheet(
        onSelected: (customer) {
          ctx.read<CartBloc>().add(CartSetCustomer(customer));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.customer?.name ?? 'Pelanggan (opsional)',
                    style: TextStyle(
                      fontWeight: state.customer != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: state.customer != null ? null : Colors.grey,
                    ),
                  ),
                ),
                if (state.customer != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        ctx.read<CartBloc>().add(CartSetCustomer(null)),
                  )
                else
                  TextButton(
                    onPressed: () => _showPicker(ctx),
                    child: const Text('Pilih'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TableBar extends StatelessWidget {
  void _showPicker(BuildContext ctx) async {
    final tables = await TableDao().getActive();
    if (!ctx.mounted) return;
    showConstrainedModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => _TablePickerSheet(
        tables: tables,
        onSelected: (table) {
          ctx.read<CartBloc>().add(CartSetTable(table));
          Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.table_restaurant, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.table?.name ?? 'Meja (opsional)',
                    style: TextStyle(
                      fontWeight: state.table != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: state.table != null ? null : Colors.grey,
                    ),
                  ),
                ),
                if (state.table != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () =>
                        ctx.read<CartBloc>().add(CartSetTable(null)),
                  )
                else
                  TextButton(
                    onPressed: () => _showPicker(ctx),
                    child: const Text('Pilih'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TablePickerSheet extends StatefulWidget {
  final List<RestoTable> tables;
  final void Function(RestoTable) onSelected;
  const _TablePickerSheet({required this.tables, required this.onSelected});

  @override
  State<_TablePickerSheet> createState() => _TablePickerSheetState();
}

class _TablePickerSheetState extends State<_TablePickerSheet> {
  final _searchCtrl = TextEditingController();
  List<RestoTable> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.tables;
  }

  void _filter(String q) {
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.tables;
      } else {
        _filtered = widget.tables
            .where((t) =>
                t.name.toLowerCase().contains(q.toLowerCase()) ||
                (t.note?.toLowerCase().contains(q.toLowerCase()) ?? false))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Meja',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Cari meja...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onChanged: _filter,
                ),
                const SizedBox(height: 12),
                if (_filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                        child: Text('Tidak ada meja',
                            style: TextStyle(color: Colors.grey))),
                  )
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: _filtered.length,
                    itemBuilder: (ctx, i) {
                      final t = _filtered[i];
                      return InkWell(
                        onTap: () => widget.onSelected(t),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(t.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('${t.capacity} kursi',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600)),
                              if (t.note != null) ...[
                                const SizedBox(height: 4),
                                Text(t.note!,
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey.shade500),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                if (item.bundleName != null)
                  Text(item.bundleName!,
                      style:
                          const TextStyle(color: Colors.orange, fontSize: 11)),
                if (item.variant != null)
                  Text(item.variant!.name,
                      style: const TextStyle(color: Colors.blue, fontSize: 11)),
                Text(fmt.format(item.effectivePrice),
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          if (item.bundleId == null) ...[
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.remove_circle_outline, size: 22),
              onPressed: () => context
                  .read<CartBloc>()
                  .add(CartUpdateQty(item.cartKey, item.qty - 1)),
            ),
            Text('${item.qty}',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            IconButton(
              constraints: const BoxConstraints(),
              padding: const EdgeInsets.all(4),
              icon: const Icon(Icons.add_circle_outline, size: 22),
              onPressed: () => context
                  .read<CartBloc>()
                  .add(CartUpdateQty(item.cartKey, item.qty + 1)),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('${item.qty}x',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          const SizedBox(width: 4),
          SizedBox(
            width: 90,
            child: Text(fmt.format(item.subtotal),
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _DiscountBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, state) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            const Text('Diskon:'),
            const SizedBox(width: 8),
            if (state.discount != null) ...[
              Text(
                state.discount!.type == DiscountType.percent
                    ? '${state.discount!.value.toStringAsFixed(0)}%'
                    : NumberFormat.currency(
                            locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                        .format(state.discount!.value),
                style: const TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () =>
                    ctx.read<CartBloc>().add(CartApplyDiscount(null)),
              ),
            ] else
              TextButton(
                onPressed: () => _showDiscountDialog(ctx),
                child: const Text('+ Tambah Diskon'),
              ),
          ],
        ),
      ),
    );
  }

  void _showDiscountDialog(BuildContext ctx) {
    final ctrl = TextEditingController();
    DiscountType type = DiscountType.percent;
    final fmt = NumberFormat('#,###', 'id_ID');

    void formatCurrency() {
      if (type != DiscountType.nominal) return;
      final text = ctrl.text.replaceAll('.', '');
      if (text.isEmpty) return;
      final parsed = int.tryParse(text);
      if (parsed == null) return;
      final formatted = fmt.format(parsed);
      if (ctrl.text != formatted) {
        ctrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    ctrl.addListener(formatCurrency);

    showConstrainedDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setState) => AlertDialog(
          title: const Text('Tambah Diskon'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SegmentedButton<DiscountType>(
                segments: const [
                  ButtonSegment(
                      value: DiscountType.percent, label: Text('Persen (%)')),
                  ButtonSegment(
                      value: DiscountType.nominal, label: Text('Nominal')),
                ],
                selected: {type},
                onSelectionChanged: (s) {
                  setState(() {
                    type = s.first;
                    if (type == DiscountType.nominal) {
                      formatCurrency();
                    } else {
                      final raw = ctrl.text.replaceAll('.', '');
                      if (raw != ctrl.text) {
                        ctrl.value = TextEditingValue(
                          text: raw,
                          selection:
                              TextSelection.collapsed(offset: raw.length),
                        );
                      }
                    }
                  });
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: type == DiscountType.nominal
                      ? 'Nilai Diskon (Rp)'
                      : 'Nilai Diskon (%)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                ctrl.removeListener(formatCurrency);
                ctrl.dispose();
                Navigator.pop(dCtx);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final rawVal = ctrl.text.replaceAll('.', '');
                final val = double.tryParse(rawVal);
                if (val != null && val > 0) {
                  ctx.read<CartBloc>().add(
                        CartApplyDiscount(Discount(type: type, value: val)),
                      );
                }
                ctrl.removeListener(formatCurrency);
                ctrl.dispose();
                Navigator.pop(dCtx);
              },
              child: const Text('Terapkan'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoteBar extends StatelessWidget {
  void _showNoteDialog(BuildContext ctx) {
    final ctrl = TextEditingController(text: ctx.read<CartBloc>().state.note);
    showConstrainedDialog(
      context: ctx,
      builder: (dCtx) => AlertDialog(
        title: const Text('Catatan'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Contoh: Tanpa es, pedas, dll',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              ctx
                  .read<CartBloc>()
                  .add(CartSetNote(ctrl.text.isEmpty ? null : ctrl.text));
              Navigator.pop(dCtx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, state) => Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Row(
          children: [
            const Icon(Icons.note, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.note ?? 'Catatan (opsional)',
                style: TextStyle(
                  fontWeight:
                      state.note != null ? FontWeight.bold : FontWeight.normal,
                  color: state.note != null ? null : Colors.grey,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => _showNoteDialog(ctx),
              child: Text(state.note != null ? 'Edit' : 'Tambah'),
            ),
            if (state.note != null)
              GestureDetector(
                onTap: () => ctx.read<CartBloc>().add(CartSetNote(null)),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final VoidCallback? onDraftSaved;

  const _CartSummary({this.onDraftSaved});

  void _saveDraft(BuildContext ctx) {
    final authState = ctx.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id!;
    int? shiftId;
    final shiftState = ctx.read<ShiftBloc>().state;
    if (shiftState is ShiftOpen) {
      shiftId = shiftState.shift.id;
    }
    ctx.read<CartBloc>().add(CartSaveDraft(userId: userId, shiftId: shiftId));
    ScaffoldMessenger.of(ctx).showSnackBar(
      const SnackBar(content: Text('Draft tersimpan')),
    );
    onDraftSaved?.call();
  }

  Future<void> _printTempReceipt(BuildContext ctx) async {
    final state = ctx.read<CartBloc>().state;
    if (state.items.isEmpty) return;

    // Check Bluetooth
    final btState = await FlutterBluePlus.adapterState.first;
    if (btState != BluetoothAdapterState.on) {
      if (ctx.mounted) {
        showDialog(
          context: ctx,
          builder: (dCtx) => AlertDialog(
            title: const Text('Bluetooth Mati'),
            content: const Text(
                'Nyalakan Bluetooth untuk mencetak struk sementara.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('Batal'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(dCtx);
                  await FlutterBluePlus.turnOn();
                  _printTempReceipt(ctx);
                },
                child: const Text('Nyalakan'),
              ),
            ],
          ),
        );
      }
      return;
    }
    final connected = BluetoothPrinter.isConnected ||
        await BluetoothPrinter.ensureConnected();
    if (!connected) {
      if (ctx.mounted) {
        showConstrainedModalBottomSheet(
          context: ctx,
          builder: (_) => _BluetoothPickerSheet(
            onConnected: () {
              Navigator.pop(ctx);
              _printTempReceipt(ctx);
            },
          ),
        );
      }
      return;
    }

    final now = DateTime.now();
    final tempOrder = Order(
      orderNumber: 'TMP${now.millisecondsSinceEpoch}',
      userId: 0,
      subtotal: state.subtotal,
      discountAmount: state.discountAmount,
      discountType: state.discount?.type.name,
      discountValue: state.discount?.value ?? 0,
      taxPercent: state.taxPercent,
      taxAmount: state.taxAmount,
      total: state.total,
      status: 'temporary',
      createdAt: now.toIso8601String(),
    );
    final items = state.items
        .map((i) => OrderItem(
              orderId: 0,
              productId: i.product.id!,
              productName: i.product.name,
              variantName: i.variant?.name,
              price: i.effectivePrice,
              qty: i.qty,
              subtotal: i.subtotal,
              bundleName: i.bundleName,
            ))
        .toList();

    try {
      await BluetoothPrinter.printReceipt(
        order: tempOrder,
        items: items,
        payments: const [],
        change: 0,
      );
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Struk sementara dicetak!')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Gagal cetak: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, state) {
        final fmt = NumberFormat.currency(
            locale: 'id', symbol: 'Rp ', decimalDigits: 0);
        final bottomPadding = MediaQuery.of(ctx).padding.bottom;
        return Container(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
          decoration: BoxDecoration(
            color: Theme.of(ctx).cardColor,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2))
            ],
          ),
          child: Column(
            children: [
              if (state.discountAmount > 0 || state.taxPercent > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Subtotal'),
                    Text(fmt.format(state.subtotal)),
                  ],
                ),
              if (state.discountAmount > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Diskon', style: TextStyle(color: Colors.green)),
                    Text('- ${fmt.format(state.discountAmount)}',
                        style: const TextStyle(color: Colors.green)),
                  ],
                ),
              if (state.taxPercent > 0)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pajak ${state.taxPercent.toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.blue)),
                    Text(fmt.format(state.taxAmount),
                        style: const TextStyle(color: Colors.blue)),
                  ],
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(fmt.format(state.total),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.items.isEmpty
                          ? null
                          : () => _printTempReceipt(ctx),
                      icon: const Icon(Icons.print, size: 18),
                      label: const Text('Cetak'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          state.items.isEmpty ? null : () => _saveDraft(ctx),
                      icon: const Icon(Icons.save, size: 18),
                      label: const Text('Simpan Draft'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: state.items.isEmpty
                      ? null
                      : () => Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => BlocProvider.value(
                                value: ctx.read<CartBloc>(),
                                child: const PaymentPage(),
                              ),
                            ),
                          ),
                  child: Text('Bayar ${fmt.format(state.total)}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Barcode Scanner Page
class BarcodeScanPage extends StatefulWidget {
  final BuildContext cartContext;
  const BarcodeScanPage({super.key, required this.cartContext});
  @override
  State<BarcodeScanPage> createState() => _BarcodeScanPageState();
}

class _BarcodeScanPageState extends State<BarcodeScanPage>
    with SingleTickerProviderStateMixin {
  final _dao = ProductDao();
  final _controller = MobileScannerController();
  bool _processing = false;
  late AnimationController _animCtrl;
  late Animation<double> _lineAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _lineAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanSize = size.width * 0.75;

    return Scaffold(
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) async {
              if (_processing) return;
              final code = capture.barcodes.first.rawValue;
              if (code == null) return;
              setState(() => _processing = true);
              final cartBloc = widget.cartContext.read<CartBloc>();
              final product = await _dao.getByBarcode(code);
              if (!mounted) return;
              if (product != null) {
                // Block only when manageStock is ON and product has no stock
                if (ReceiptSettings.manageStock && product.stock <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stok produk habis')),
                  );
                  setState(() => _processing = false);
                  return;
                }
                cartBloc.add(CartAddItem(product));
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Produk tidak ditemukan: $code')));
                setState(() => _processing = false);
              }
            },
          ),
          // Overlay dengan cutout
          CustomPaint(
            size: size,
            painter: _ScannerOverlayPainter(
              scanRect: Rect.fromCenter(
                center: Offset(size.width / 2, size.height / 2 - 40),
                width: scanSize,
                height: scanSize * 0.5,
              ),
              lineProgress: _lineAnim.value,
            ),
          ),
          // Tombol close
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          // Torch toggle
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.flashlight_on, color: Colors.white),
              onPressed: () => _controller.toggleTorch(),
            ),
          ),
          if (_processing)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class _ScannerOverlayPainter extends CustomPainter {
  final Rect scanRect;
  final double lineProgress;

  _ScannerOverlayPainter({required this.scanRect, required this.lineProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final innerPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)));
    final path = Path.combine(PathOperation.difference, outerPath, innerPath);

    // Background gelap di luar area scan
    canvas.drawPath(path, Paint()..color = Colors.black.withValues(alpha: 0.5));

    // Garis scan animasi
    final lineY = scanRect.top + scanRect.height * lineProgress;
    canvas.drawLine(
      Offset(scanRect.left + 4, lineY),
      Offset(scanRect.right - 4, lineY),
      Paint()
        ..color = Colors.cyan
        ..strokeWidth = 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Border sudut (corners)
    final cornerLen = 28.0;
    final stroke = Paint()
      ..color = Colors.cyan
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.top + cornerLen)
        ..lineTo(scanRect.left, scanRect.top)
        ..lineTo(scanRect.left + cornerLen, scanRect.top),
      stroke,
    );
    // Top-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLen, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top)
        ..lineTo(scanRect.right, scanRect.top + cornerLen),
      stroke,
    );
    // Bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.left, scanRect.bottom - cornerLen)
        ..lineTo(scanRect.left, scanRect.bottom)
        ..lineTo(scanRect.left + cornerLen, scanRect.bottom),
      stroke,
    );
    // Bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(scanRect.right - cornerLen, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom)
        ..lineTo(scanRect.right, scanRect.bottom - cornerLen),
      stroke,
    );
  }

  @override
  bool shouldRepaint(_ScannerOverlayPainter old) =>
      old.lineProgress != lineProgress || old.scanRect != scanRect;
}

class _DraftPickerSheet extends StatefulWidget {
  final OrderDao dao;
  final List<Order> drafts;
  final void Function(Order order, List<OrderItem> items) onPicked;
  final VoidCallback onDeleted;
  final VoidCallback? onDraftDeleted;

  const _DraftPickerSheet({
    required this.dao,
    required this.drafts,
    required this.onPicked,
    required this.onDeleted,
    this.onDraftDeleted,
  });
  @override
  State<_DraftPickerSheet> createState() => _DraftPickerSheetState();
}

class _DraftPickerSheetState extends State<_DraftPickerSheet> {
  late List<Order> _drafts;

  @override
  void initState() {
    super.initState();
    _drafts = List.from(widget.drafts);
  }

  Future<void> _delete(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Hapus Draft'),
        content: Text('Hapus draft ${order.orderNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dCtx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.dao.deleteDraftOrder(order.id!);
      if (mounted) {
        setState(() => _drafts.removeWhere((d) => d.id == order.id));
        widget.onDeleted();
        widget.onDraftDeleted?.call();
        if (_drafts.isEmpty) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.inbox),
                const SizedBox(width: 8),
                const Text('Ambil Draft',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _drafts.isEmpty
                ? const Center(child: Text('Tidak ada draft'))
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _drafts.length,
                    itemBuilder: (_, i) {
                      final order = _drafts[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            final items =
                                await widget.dao.getItemsByOrderId(order.id!);
                            widget.onPicked(order, items);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.receipt_long,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        order.orderNumber,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        dateFmt.format(
                                            DateTime.parse(order.createdAt)),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        fmt.format(order.total),
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  onPressed: () => _delete(order),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
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
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (_scanning) const CircularProgressIndicator(strokeWidth: 2),
                if (!_scanning)
                  IconButton(onPressed: _scan, icon: const Icon(Icons.refresh)),
              ],
            ),
            const Divider(),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView(
                shrinkWrap: true,
                children: [
                  ..._devices.map((d) => ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(d.platformName.isEmpty
                            ? d.remoteId.str
                            : d.platformName),
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
          ],
        ),
      ),
    );
  }
}

class _CustomerPickerSheet extends StatefulWidget {
  final void Function(Customer) onSelected;
  const _CustomerPickerSheet({required this.onSelected});
  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  final _dao = CustomerDao();
  List<Customer> _customers = [];
  List<Customer> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _dao.getAll();
    if (mounted)
      setState(() {
        _customers = list;
        _filtered = list;
      });
  }

  void _onSearch(String v) {
    if (v.isEmpty) {
      setState(() => _filtered = _customers);
    } else {
      setState(() => _filtered = _customers
          .where((c) =>
              c.name.toLowerCase().contains(v.toLowerCase()) ||
              (c.phone?.contains(v) ?? false))
          .toList());
    }
  }

  Future<void> _createCustomer() async {
    final nameCtrl = TextEditingController(text: _searchCtrl.text);
    final phoneCtrl = TextEditingController();
    final result = await showConstrainedDialog<Customer>(
      context: context,
      builder: (dCtx) => AlertDialog(
        title: const Text('Tambah Pelanggan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'No. Telepon (opsional)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dCtx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final now = DateTime.now().toIso8601String();
              Navigator.pop(
                  dCtx,
                  Customer(
                    name: nameCtrl.text.trim(),
                    phone: phoneCtrl.text.trim().isEmpty
                        ? null
                        : phoneCtrl.text.trim(),
                    createdAt: now,
                  ));
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (result != null) {
      final id = await _dao.insert(result);
      final saved = Customer(
          id: id,
          name: result.name,
          phone: result.phone,
          createdAt: result.createdAt);
      if (mounted) _searchCtrl.text = saved.name;
      widget.onSelected(saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person),
                const SizedBox(width: 8),
                const Text('Pilih Pelanggan',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                hintText: 'Cari pelanggan...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _onSearch,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _createCustomer,
                icon: const Icon(Icons.person_add, size: 18),
                label: const Text('Tambah Pelanggan Baru'),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _filtered.isEmpty
                  ? LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 110;
                        final color =
                            Theme.of(context).colorScheme.onSurfaceVariant;
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_off,
                                size: compact ? 36 : 64,
                                color: color,
                              ),
                              SizedBox(height: compact ? 4 : 8),
                              Text(
                                _searchCtrl.text.trim().isNotEmpty
                                    ? 'Pelanggan tidak ditemukan'
                                    : 'Tidak ada pelanggan',
                                style: TextStyle(
                                  color: color,
                                  fontSize: compact ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                c.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(c.name),
                            subtitle: c.phone != null ? Text(c.phone!) : null,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => widget.onSelected(c),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

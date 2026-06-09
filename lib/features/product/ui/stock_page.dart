import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/stock_bloc.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/responsive_dialog.dart';

class StockPage extends StatelessWidget {
  final bool isAdmin;
  const StockPage({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    context.read<StockBloc>().add(StockLoad());
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Stok'),
          bottom: const TabBar(tabs: [
            Tab(text: 'Semua Produk'),
            Tab(text: 'Stok Rendah'),
          ]),
        ),
        body: BlocBuilder<StockBloc, StockState>(
          builder: (ctx, state) {
            if (state is StockLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is StockLoaded) {
              return TabBarView(children: [
                _StockList(products: state.products, isAdmin: isAdmin),
                _StockList(
                    products: state.lowStockProducts,
                    isAdmin: isAdmin,
                    emptyMessage: 'Semua stok aman'),
              ]);
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }
}

class _StockList extends StatelessWidget {
  final List<Product> products;
  final String emptyMessage;
  final bool isAdmin;
  const _StockList({
    required this.products,
    this.emptyMessage = 'Tidak ada produk',
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(child: Text(emptyMessage));
    }
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (ctx, i) {
        final p = products[i];
        return ListTile(
          title: Text(p.name),
          subtitle: Text(p.categoryName ?? '-'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: p.stock <= 0
                      ? Colors.red
                      : p.stock <= 5
                          ? Colors.orange
                          : Colors.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${p.stock} ${p.unit}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showAdjustDialog(ctx, p),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAdjustDialog(BuildContext ctx, Product product) {
    String type = 'in';
    final qtyCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    showConstrainedDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setState) => AlertDialog(
          title: Text('Adjust Stok: ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stok saat ini: ${product.stock} ${product.unit}'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _typeChip('Masuk', 'in', type, (v) => setState(() => type = v)),
                  _typeChip('Keluar', 'out', type, (v) => setState(() => type = v)),
                  _typeChip('Sesuaikan', 'adjustment', type,
                      (v) => setState(() => type = v)),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: qtyCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Jumlah', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(dCtx),
                child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text);
                if (qty != null && qty > 0) {
                  ctx.read<StockBloc>().add(StockAdjust(
                        productId: product.id!,
                        type: type,
                        qty: qty,
                        note: noteCtrl.text.trim().isEmpty
                            ? null
                            : noteCtrl.text.trim(),
                      ));
                  Navigator.pop(dCtx);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeChip(
      String label, String value, String current, ValueChanged<String> onTap) {
    return GestureDetector(
      onTap: () => onTap(value),
      child: Chip(
        label: Text(label,
            style: TextStyle(
                color: current == value ? Colors.white : null)),
        backgroundColor:
            current == value ? Colors.blue : null,
      ),
    );
  }
}

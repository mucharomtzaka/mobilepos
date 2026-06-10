import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/bundle_bloc.dart';
import '../../../core/database/bundle_dao.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/models/bundle.dart';
import '../../../core/models/bundle_item.dart';
import '../../../core/models/product.dart';
import '../../../core/utils/responsive_page_insets.dart';

class BundlePage extends StatelessWidget {
  const BundlePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => BundleBloc(BundleDao())..add(BundleLoad()),
      child: const _BundleView(),
    );
  }
}

class _BundleView extends StatefulWidget {
  const _BundleView();

  @override
  State<_BundleView> createState() => _BundleViewState();
}

class _BundleViewState extends State<_BundleView> {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  final _dao = BundleDao();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final state = context.read<BundleBloc>().state;
    if (state is! BundleLoaded || !state.hasMore) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<BundleBloc>().add(BundleLoadMore(search: _searchCtrl.text));
    }
  }

  void _reload() {
    context.read<BundleBloc>().add(BundleLoad(search: _searchCtrl.text));
  }

  Future<void> _openForm([Bundle? bundle]) async {
    final items = bundle?.id == null ? null : await _dao.getItems(bundle!.id!);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<BundleBloc>(),
          child: BundleFormPage(bundle: bundle, bundleItems: items),
        ),
      ),
    );
    if (mounted) _reload();
  }

  Future<void> _delete(Bundle bundle) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Bundling'),
        content: Text('Hapus paket "${bundle.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      context.read<BundleBloc>().add(BundleDelete(bundle.id!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Paket Bundling'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: ResponsivePageInsets.horizontal(context, maxContentWidth: 920),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Cari bundling...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (_) => _reload(),
              ),
            ),
            Expanded(
              child: BlocBuilder<BundleBloc, BundleState>(
                builder: (context, state) {
                  if (state is BundleLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is BundleLoaded) {
                    if (state.bundles.isEmpty) {
                      return Center(
                        child: Text(
                          _searchCtrl.text.isEmpty
                              ? 'Belum ada paket bundling'
                              : 'Bundling tidak ditemukan',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: state.bundles.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= state.bundles.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final bundle = state.bundles[i];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Icon(
                                Icons.redeem,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onPrimaryContainer,
                              ),
                            ),
                            title: Text(bundle.name),
                            subtitle: Text(fmt.format(bundle.price)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline,
                                  color: Colors.red),
                              onPressed: () => _delete(bundle),
                            ),
                            onTap: () => _openForm(bundle),
                          ),
                        );
                      },
                    );
                  }
                  if (state is BundleError) {
                    return Center(child: Text(state.message));
                  }
                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BundleFormPage extends StatefulWidget {
  final Bundle? bundle;
  final List<BundleItem>? bundleItems;
  const BundleFormPage({super.key, this.bundle, this.bundleItems});

  @override
  State<BundleFormPage> createState() => _BundleFormPageState();
}

class _BundleFormPageState extends State<BundleFormPage> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _priceFmt = NumberFormat('#,###', 'id_ID');
  final List<_BundleItemEntry> _items = [];
  List<Product> _allProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.bundle?.name ?? '';
    if (widget.bundle != null) {
      _priceCtrl.text = _priceFmt.format(widget.bundle!.price.toInt());
    }
    _priceCtrl.addListener(_formatPrice);
    _load();
  }

  void _formatPrice() {
    final text = _priceCtrl.text.replaceAll('.', '');
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    final formatted = _priceFmt.format(parsed);
    if (_priceCtrl.text != formatted) {
      _priceCtrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  Future<void> _load() async {
    final dao = ProductDao();
    final products = await dao.getAll();
    if (widget.bundleItems != null) {
      for (final bi in widget.bundleItems!) {
        final product = products.firstWhere((p) => p.id == bi.productId,
            orElse: () => products.first);
        _items.add(_BundleItemEntry(product: product, qty: bi.qty));
      }
    }
    if (mounted) {
      setState(() {
        _allProducts = products;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.removeListener(_formatPrice);
    _priceCtrl.dispose();
    super.dispose();
  }

  double? get _parsedPrice {
    final raw = _priceCtrl.text.replaceAll('.', '');
    return double.tryParse(raw);
  }

  void _addProduct(Product p) {
    setState(() {
      _items.add(_BundleItemEntry(product: p, qty: 1));
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final price = _parsedPrice;
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nama bundling harus diisi')));
      return;
    }
    if (price == null || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Harga bundling harus diisi')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal 1 produk')));
      return;
    }

    final now = DateTime.now().toIso8601String();
    final bundle = Bundle(
      id: widget.bundle?.id,
      name: name,
      price: price,
      isActive: true,
      createdAt: widget.bundle?.createdAt ?? now,
    );
    final items = _items
        .map((i) => BundleItem(
              bundleId: widget.bundle?.id ?? 0,
              productId: i.product.id!,
              qty: i.qty,
            ))
        .toList();

    if (widget.bundle != null) {
      context.read<BundleBloc>().add(BundleUpdate(bundle, items));
    } else {
      context.read<BundleBloc>().add(BundleAdd(bundle, items));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final priceFmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.bundle != null ? 'Edit Bundling' : 'Buat Bundling'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: ResponsivePageInsets.horizontal(context,
                  maxContentWidth: 640),
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        TextField(
                          controller: _nameCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Bundling',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Harga Bundling (Rp)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Expanded(
                              child: Text('Produk dalam Bundling',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ),
                            TextButton(
                              onPressed: () => _showProductPicker(context),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.add, size: 16),
                                  SizedBox(width: 4),
                                  Text('Tambah'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (_items.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(
                              child: Text('Belum ada produk',
                                  style: TextStyle(color: Colors.grey)),
                            ),
                          ),
                        ..._items.asMap().entries.map((entry) {
                          final i = entry.value;
                          final idx = entry.key;
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(i.product.name,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        Text(
                                          priceFmt.format(i.product.price),
                                          style: const TextStyle(
                                              color: Colors.grey, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => _removeItem(idx),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      child: const Icon(
                                          Icons.remove_circle_outline,
                                          color: Colors.red,
                                          size: 20),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      GestureDetector(
                                        onTap: i.qty > 1
                                            ? () => setState(() => i.qty--)
                                            : null,
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child: const Icon(Icons.remove,
                                              size: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      Text('${i.qty}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 2),
                                      GestureDetector(
                                        onTap: () => setState(() => i.qty++),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          child:
                                              const Icon(Icons.add, size: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _save,
                          child: Text(widget.bundle != null
                              ? 'Simpan Perubahan'
                              : 'Simpan Bundling'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  void _showProductPicker(BuildContext ctx) {
    final available = _allProducts
        .where((p) => !_items.any((i) => i.product.id == p.id))
        .toList();
    showModalBottomSheet(
      context: ctx,
      builder: (ctx) => _ProductPickerSheet(
        products: available,
        onSelected: (p) {
          Navigator.pop(ctx);
          _addProduct(p);
        },
      ),
    );
  }
}

class _BundleItemEntry {
  final Product product;
  int qty;
  _BundleItemEntry({required this.product, this.qty = 1});
}

class _ProductPickerSheet extends StatefulWidget {
  final List<Product> products;
  final void Function(Product) onSelected;
  const _ProductPickerSheet({required this.products, required this.onSelected});

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  late List<Product> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.products;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _search(String q) {
    setState(() {
      if (q.isEmpty) {
        _filtered = widget.products;
      } else {
        _filtered = widget.products
            .where((p) => p.name.toLowerCase().contains(q.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Text('Pilih Produk',
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
                hintText: 'Cari produk...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 8),
            if (_filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Tidak ada produk tersedia'),
              )
            else
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: _filtered
                      .map((p) => ListTile(
                            leading: CircleAvatar(
                              child: Text(p.name[0].toUpperCase()),
                            ),
                            title: Text(p.name),
                            subtitle: Text(fmt.format(p.price)),
                            onTap: () => widget.onSelected(p),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

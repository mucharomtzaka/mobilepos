import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/product_bloc.dart';
import '../../../core/models/category.dart';
import 'product_form_page.dart';

class ProductPage extends StatefulWidget {
  const ProductPage({super.key});
  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final _search = TextEditingController();
  int? _selectedCategoryId;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    context.read<ProductBloc>().add(ProductLoad());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        context.read<ProductBloc>().state is ProductLoaded) {
      final state = context.read<ProductBloc>().state as ProductLoaded;
      if (state.hasMore) {
        context.read<ProductBloc>().add(
              ProductLoadMore(
                categoryId: _selectedCategoryId,
                search: _search.text,
              ),
            );
      }
    }
  }

  void _reload() => context.read<ProductBloc>().add(
        ProductLoad(categoryId: _selectedCategoryId, search: _search.text),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produk'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.category),
              tooltip: 'Kelola Kategori',
              onPressed: () => Navigator.pushNamed(context, '/categories')
                  .then((_) => _reload()),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: context.read<ProductBloc>(),
              child: const ProductFormPage(),
            ),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<ProductBloc, ProductState>(
        builder: (ctx, state) {
          final categories =
              state is ProductLoaded ? state.categories : <Category>[];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _search,
                        decoration: const InputDecoration(
                          hintText: 'Cari produk...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _reload(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: DropdownButton<int?>(
                        value: categories.any((c) => c.id == _selectedCategoryId) ? _selectedCategoryId : null,
                        hint: const Text('Semua'),
                        underline: const SizedBox(),
                        items: [
                          const DropdownMenuItem(
                              value: null, child: Text('Semua')),
                          ...categories.map((c) => DropdownMenuItem(
                              value: c.id, child: Text(c.name))),
                        ],
                        onChanged: (v) {
                          setState(() => _selectedCategoryId = v);
                          _reload();
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildList(ctx, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildList(BuildContext ctx, ProductState state) {
    if (state is ProductLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state is ProductLoaded) {
      if (state.products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2, size: 64,
                  color: Theme.of(ctx).colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text('Belum ada produk',
                  style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('Tekan + untuk menambah produk',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
            ],
          ),
        );
      }
      return ListView.builder(
        controller: _scrollController,
        itemCount: state.products.length + (state.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i >= state.products.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final p = state.products[i];
          return ListTile(
            leading: p.imagePath != null
                ? CircleAvatar(
                    backgroundImage: FileImage(File(p.imagePath!)),
                  )
                : CircleAvatar(child: Text(p.name[0].toUpperCase())),
            title: Text(p.name),
            subtitle: Text(
                '${p.categoryName ?? '-'} • Stok: ${p.stock} ${p.unit}'),
            trailing: Text(
              NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)
                  .format(p.price),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: ctx.read<ProductBloc>(),
                  child: ProductFormPage(product: p),
                ),
              ),
            ),
          );
        },
      );
    }
    return const SizedBox();
  }
}

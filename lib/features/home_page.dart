import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'auth/bloc/auth_bloc.dart';
import 'cart/bloc/cart_bloc.dart';
import 'cart/ui/cart_page.dart';
import 'payment/ui/payment_page.dart';
import 'product/bloc/product_bloc.dart';
import 'shift/bloc/shift_bloc.dart';
import 'cashflow/ui/finance_page.dart';
import 'report/ui/report_page.dart';
import 'settings/ui/settings_page.dart';
import 'settings/ui/profile_page.dart';
import '../core/database/product_dao.dart';
import '../core/database/customer_dao.dart';
import '../core/models/cart_item.dart';
import '../core/models/customer.dart';
import '../core/utils/receipt_settings.dart';
import '../core/utils/responsive_dialog.dart';
import '../core/database/settings_dao.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final ProductBloc _productBloc = ProductBloc(ProductDao(), CategoryDao());

  @override
  void initState() {
    super.initState();
    _productBloc.add(ProductLoad());
    context.read<CartBloc>().add(CartSetTaxPercent(ReceiptSettings.taxPercent));
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<ShiftBloc>().add(ShiftCheck(authState.user.id!));
    }
  }

  @override
  void dispose() {
    _productBloc.close();
    super.dispose();
  }

  void _onTabChanged(int i) {
    if (i == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FinancePage()),
      );
      return;
    }
    if (i == 0) _productBloc.add(ProductLoad());
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      });
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final user = authState.user;

    final pages = [
      _PosTab(productBloc: _productBloc),
      const ReportPage(),
      const FinancePage(),
      const SettingsPage(),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/images/logo.png', height: 32),
            ),
            const SizedBox(width: 8),
            const Text('Drone POS', style: TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              child: Text(
                user.name.isNotEmpty
                    ? user.name.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
            tooltip: 'Profil',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.settings),
                  title: Text('Pengaturan'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  dense: true,
                  leading: Icon(Icons.logout, color: Colors.red),
                  title: Text('Keluar'),
                ),
              ),
            ],
            onSelected: (v) {
              if (v == 'logout') {
                context.read<AuthBloc>().add(AuthLogoutRequested());
              } else if (v == 'settings') {
                Navigator.push(context,
                    MaterialPageRoute(
                        builder: (_) => const SettingsPage())).then((_) => _productBloc.add(ProductLoad()));
              }
            },
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          color: Theme.of(context).primaryColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _onTabChanged,
            backgroundColor: Colors.transparent,
            indicatorColor: Colors.white,
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                );
              }
              return TextStyle(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.7),
              );
            }),
            destinations: const [
              NavigationDestination(
                  icon: Icon(Icons.shopping_cart), label: 'Kasir'),
              NavigationDestination(
                  icon: Icon(Icons.history), label: 'History'),
              NavigationDestination(
                  icon: Icon(Icons.account_balance), label: 'Keuangan'),
              NavigationDestination(
                  icon: Icon(Icons.settings), label: 'Pengaturan'),
            ],
          ),
        ),
      ),
    );
  }
}

// POS Tab
class _PosTab extends StatelessWidget {
  final ProductBloc productBloc;
  const _PosTab({required this.productBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: productBloc,
      child: const _PosView(),
    );
  }
}

class _PosView extends StatefulWidget {
  const _PosView();
  @override
  State<_PosView> createState() => _PosViewState();
}

class _PosViewState extends State<_PosView> {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    if (currentScroll >= maxScroll - 200) {
      final state = context.read<ProductBloc>().state;
      if (state is ProductLoaded && state.hasMore) {
        context.read<ProductBloc>().add(ProductLoadMore(
          categoryId: _categoryId,
          search: _searchCtrl.text,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        if (constraints.maxWidth > 800) {
          return _buildTabletLayout();
        }
        return _buildPhoneLayout();
      },
    );
  }

  Widget _buildProductArea({bool compact = false}) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => context
                      .read<ProductBloc>()
                      .add(ProductLoad(categoryId: _categoryId, search: v)),
                ),
              ),
            ],
          ),
        ),
        // Product grid
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (ctx, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductLoaded) {
                return Column(
                  children: [
                    // Category filter
                    if (state.categories.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          children: [
                            _CategoryChip(
                              label: 'Semua',
                              isSelected: _categoryId == null,
                              onTap: () {
                                setState(() => _categoryId = null);
                                ctx.read<ProductBloc>().add(ProductLoad());
                              },
                            ),
                            ...state.categories.map((c) => _CategoryChip(
                              label: c.name,
                              isSelected: _categoryId == c.id,
                              onTap: () {
                                setState(() => _categoryId = c.id);
                                ctx.read<ProductBloc>().add(ProductLoad(categoryId: c.id));
                              },
                            )),
                          ],
                        ),
                      ),
                    Expanded(
                      child: state.products.isEmpty
                          ? const Center(child: Text('Tidak ada produk'))
                          : LayoutBuilder(
                              builder: (ctx, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount = compact
                                    ? (width > 800 ? 6 : 5)
                                    : (width > 800 ? 5 : width > 600 ? 4 : 3);
                                return GridView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.all(compact ? 4 : 8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: compact ? 0.65 : 0.75,
                                    crossAxisSpacing: compact ? 4 : 8,
                                    mainAxisSpacing: compact ? 4 : 8,
                                  ),
                                  itemCount: state.products.length + (state.hasMore ? 1 : 0),
                                  itemBuilder: (_, i) {
                                    if (i >= state.products.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final p = state.products[i];
                                    return _ProductCard(product: p, compact: compact);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: _buildProductArea(compact: true),
        ),
        Container(
          width: 1,
          color: Colors.grey[300],
        ),
        Expanded(
          flex: 2,
          child: _buildCartSidebar(),
        ),
      ],
    );
  }

  Widget _buildPhoneLayout() {
    return Column(
      children: [
        // Search bar + cart button
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Cari produk...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (v) => context
                      .read<ProductBloc>()
                      .add(ProductLoad(categoryId: _categoryId, search: v)),
                ),
              ),
              const SizedBox(width: 8),
              BlocBuilder<CartBloc, CartState>(
                builder: (ctx, cart) => Container(
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Badge(
                    isLabelVisible: cart.itemCount > 0,
                    label: Text('${cart.itemCount}'),
                    child: IconButton(
                      icon: const Icon(Icons.shopping_cart),
                      onPressed: () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: ctx.read<CartBloc>(),
                            child: const CartPage(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<ProductBloc, ProductState>(
            builder: (ctx, state) {
              if (state is ProductLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ProductLoaded) {
                return Column(
                  children: [
                    if (state.categories.isNotEmpty)
                      SizedBox(
                        height: 44,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          children: [
                            _CategoryChip(
                              label: 'Semua',
                              isSelected: _categoryId == null,
                              onTap: () {
                                setState(() => _categoryId = null);
                                ctx.read<ProductBloc>().add(ProductLoad());
                              },
                            ),
                            ...state.categories.map((c) => _CategoryChip(
                              label: c.name,
                              isSelected: _categoryId == c.id,
                              onTap: () {
                                setState(() => _categoryId = c.id);
                                ctx.read<ProductBloc>().add(ProductLoad(categoryId: c.id));
                              },
                            )),
                          ],
                        ),
                      ),
                    Expanded(
                      child: state.products.isEmpty
                          ? const Center(child: Text('Tidak ada produk'))
                          : LayoutBuilder(
                              builder: (ctx, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount = width > 800 ? 5 : width > 600 ? 4 : 3;
                                return GridView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: state.products.length + (state.hasMore ? 1 : 0),
                                  itemBuilder: (_, i) {
                                    if (i >= state.products.length) {
                                      return const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(16),
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    final p = state.products[i];
                                    return _ProductCard(product: p);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
        // Mini cart summary bar
        BlocBuilder<CartBloc, CartState>(
          builder: (ctx, cart) {
            if (cart.items.isEmpty) return const SizedBox();
            final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            return Container(
              color: Theme.of(ctx).primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('${cart.itemCount} item',
                      style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text(fmt.format(cart.total),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white),
                    onPressed: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: ctx.read<CartBloc>(),
                          child: const CartPage(),
                        ),
                      ),
                    ),
                    child: Text('Bayar',
                        style: TextStyle(
                            color: Theme.of(ctx).colorScheme.primary)),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomerBar(BuildContext ctx, CartState cart) {
    final dao = CustomerDao();
    return GestureDetector(
      onTap: () => _showCustomerPicker(ctx),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(Icons.person, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                cart.customer?.name ?? 'Pilih Pelanggan',
                style: TextStyle(
                  fontSize: 12,
                  color: cart.customer != null ? null : Colors.grey,
                  fontWeight:
                      cart.customer != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (cart.customer != null)
              GestureDetector(
                onTap: () => ctx.read<CartBloc>().add(CartSetCustomer(null)),
                child: const Icon(Icons.close, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  void _showCustomerPicker(BuildContext ctx) {
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

  Widget _buildCartSidebar() {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, cart) {
        return Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(12),
              color: Theme.of(ctx).primaryColor,
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Keranjang',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (cart.items.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete_sweep, color: Colors.white),
                      tooltip: 'Kosongkan',
                      onPressed: () {
                        context.read<CartBloc>().add(CartClear());
                      },
                    ),
                  Text(
                    '${cart.itemCount} item',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
            // Customer
            _buildCustomerBar(ctx, cart),
            // Cart items list
            Expanded(
              child: cart.items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.shopping_cart_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: 8),
                          Text('Keranjang kosong', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: cart.items.length,
                      itemBuilder: (_, i) {
                        final item = cart.items[i];
                        return Card(
                          child: ListTile(
                            dense: true,
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: Text(
                                  '${item.qty}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Theme.of(ctx).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              item.product.name,
                              style: const TextStyle(fontSize: 13),
                            ),
                            subtitle: item.variant != null
                                ? Text(
                                    item.variant!.name,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey[600],
                                    ),
                                  )
                                : null,
                            trailing: SizedBox(
                              width: 90,
                              child: Text(
                                fmt.format(item.subtotal),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () => _showCartItemOptions(ctx, item),
                          ),
                        );
                      },
                    ),
            ),
            // Summary
            if (cart.items.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // Discount input
                    Row(
                      children: [
                        const Text('Diskon',
                            style: TextStyle(fontSize: 13)),
                        const Spacer(),
                        SizedBox(
                          width: 100,
                          height: 32,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              isDense: true,
                              hintText: '0',
                              border: OutlineInputBorder(),
                              contentPadding:
                                  EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onChanged: (v) {
                              final disc = int.tryParse(v) ?? 0;
                              ctx.read<CartBloc>().add(CartApplyDiscount(
                                disc > 0 ? Discount(type: DiscountType.nominal, value: disc.toDouble()) : null,
                              ));
                            },
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    // Total
                    Row(
                      children: [
                        const Text('Total',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(fmt.format(cart.total),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(ctx).primaryColor,
                            )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: ctx.read<CartBloc>(),
                              child: const PaymentPage(),
                            ),
                          ),
                        ),
                        child: const Text('Bayar',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  void _showCartItemOptions(BuildContext context, dynamic item) {
    showConstrainedModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
            title: const Text('Hapus'),
            onTap: () {
              context.read<CartBloc>().add(CartRemoveItem(item.cartKey));
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Ubah Qty'),
            onTap: () {
              Navigator.pop(ctx);
              _showQtyDialog(context, item);
            },
          ),
        ],
      ),
    );
  }

  void _showQtyDialog(BuildContext context, dynamic item) {
    final controller = TextEditingController(text: '${item.quantity}');
    showConstrainedDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ubah Jumlah'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Jumlah',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final qty = int.tryParse(controller.text);
              if (qty != null && qty > 0) {
                context.read<CartBloc>().add(CartUpdateQty(
                  item.cartKey,
                  qty,
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

void _showVariantPicker(BuildContext context, dynamic product) {
  final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  showConstrainedDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(product.name),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Base product option
            ListTile(
              dense: true,
              leading: const Icon(Icons.shopping_cart),
              title: const Text('Harga Dasar',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(fmt.format(product.price)),
              onTap: () async {
                // Block only when manageStock is ON and product has no stock
                if (ReceiptSettings.manageStock && product.stock <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stok produk habis')),
                  );
                  return;
                }
                context.read<CartBloc>().add(CartAddItem(product));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${product.name} ditambahkan'),
                  duration: const Duration(milliseconds: 500),
                ));
              },
            ),
            const Divider(),
            Text('Varian:',
                style: TextStyle(fontSize: 13, color: Colors.grey[600])),
            const SizedBox(height: 4),
            ...product.variants.map<Widget>((v) => ListTile(
              dense: true,
              title: Text(v.name),
              subtitle: Text(fmt.format(product.price + v.priceAdjustment)),
              onTap: () async {
                // Block only when manageStock is ON and variant has no stock
                if (ReceiptSettings.manageStock && v.stock <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Stok ${v.name} habis')),
                  );
                  return;
                }
                context.read<CartBloc>().add(CartAddItem(product, variant: v));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${product.name} - ${v.name} ditambahkan'),
                  duration: const Duration(milliseconds: 500),
                ));
              },
            )),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Batal'),
        ),
      ],
    ),
  );
}

class _ProductCard extends StatelessWidget {
  final dynamic product;
  final bool compact;
  const _ProductCard({required this.product, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return GestureDetector(
      onTap: () {
          if (ReceiptSettings.manageStock && product.stock <= 0) {
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Stok habis!')));
            return;
          }
        if (product.hasVariants) {
          _showVariantPicker(context, product);
          return;
        }
        context.read<CartBloc>().add(CartAddItem(product));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${product.name} ditambahkan'),
          duration: const Duration(milliseconds: 500),
        ));
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 4 : 8),
          side: BorderSide(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 4 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(compact ? 4 : 8),
                  child: product.imagePath != null
                      ? Image.file(
                          File(product.imagePath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) =>
                              _ProductInitial(name: product.name, outOfStock: ReceiptSettings.manageStock && product.stock <= 0),
                        )
                      : _ProductInitial(name: product.name, outOfStock: ReceiptSettings.manageStock && product.stock <= 0),
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                product.name.length > (compact ? 15 : 20)
                    ? '${product.name.substring(0, compact ? 12 : 17)}...'
                    : product.name,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Text(
                fmt.format(product.price),
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.greenAccent
                      : Colors.green,
                ),
              ),
              if (ReceiptSettings.manageStock && product.stock <= 5)
                Text(
                  'Stok: ${product.stock}',
                  style: TextStyle(
                    fontSize: compact ? 8 : 10,
                    color: product.stock <= 0
                        ? Colors.red
                        : Theme.of(context).brightness == Brightness.dark
                            ? Colors.orange
                            : Colors.orange,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductInitial extends StatelessWidget {
  final String name;
  final bool outOfStock;
  const _ProductInitial({required this.name, this.outOfStock = false});

  Color _colorFromName(String name) {
    const colors = [
      Colors.blue, Colors.teal, Colors.purple, Colors.indigo,
      Colors.orange, Colors.pink, Colors.cyan, Colors.green,
    ];
    return colors[name.codeUnitAt(0) % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return _build(context);
  }

  Widget _build(BuildContext context) {
    final color = _colorFromName(name);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: outOfStock
            ? (isDark ? Colors.grey.shade800 : Colors.grey.shade200)
            : color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: outOfStock ? Colors.grey : color),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
             name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                color: outOfStock
                    ? (isDark ? Colors.grey.shade500 : Colors.grey)
                    : (isDark ? Colors.white : Colors.black87),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
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
    if (mounted) setState(() {
      _customers = list;
      _filtered = list;
    });
  }

  void _onSearch(String v) {
    if (v.isEmpty) {
      setState(() => _filtered = _customers);
    } else {
      setState(() => _filtered = _customers.where((c) =>
          c.name.toLowerCase().contains(v.toLowerCase()) ||
          (c.phone?.contains(v) ?? false)).toList());
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
              Navigator.pop(dCtx, Customer(
                name: nameCtrl.text.trim(),
                phone: phoneCtrl.text.trim().isEmpty
                    ? null : phoneCtrl.text.trim(),
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
      final saved = Customer(id: id, name: result.name,
          phone: result.phone, createdAt: result.createdAt);
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 64,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _searchCtrl.text.trim().isNotEmpty
                                ? 'Pelanggan tidak ditemukan'
                                : 'Tidak ada pelanggan',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) {
                        final c = _filtered[i];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                c.name[0].toUpperCase(),
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
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

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: activeColor.withValues(alpha: 0.2),
        checkmarkColor: activeColor,
        labelStyle: TextStyle(
          color: isSelected
              ? activeColor
              : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

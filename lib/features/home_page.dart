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
import '../core/database/bundle_dao.dart';
import '../core/models/cart_item.dart';
import '../core/models/bundle.dart';
import '../core/models/customer.dart';
import '../core/utils/receipt_settings.dart';
import '../core/utils/responsive_dialog.dart';
import '../core/database/settings_dao.dart';
import '../core/database/order_dao.dart';
import '../core/database/table_dao.dart';
import '../core/models/table.dart';
import '../core/models/order.dart';
import '../l10n/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  final ProductBloc _productBloc = ProductBloc(ProductDao(), CategoryDao());
  final GlobalKey<_PosViewState> _posKey = GlobalKey();

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
    if (i == 0) {
      _productBloc.add(ProductLoad());
      _posKey.currentState?.reloadBundles();
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final l10n = AppLocalizations.of(context)!;
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
      _PosTab(productBloc: _productBloc, posKey: _posKey),
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
                        MaterialPageRoute(builder: (_) => const SettingsPage()))
                    .then((_) {
                  _productBloc.add(ProductLoad());
                  _posKey.currentState?.reloadBundles();
                });
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
            destinations: [
              NavigationDestination(
                  icon: const Icon(Icons.shopping_cart),
                  label: l10n.cashier),
              NavigationDestination(
                  icon: const Icon(Icons.history),
                  label: l10n.history),
              NavigationDestination(
                  icon: const Icon(Icons.account_balance),
                  label: l10n.finance),
              NavigationDestination(
                  icon: const Icon(Icons.settings),
                  label: l10n.settings),
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
  final GlobalKey<_PosViewState>? posKey;
  const _PosTab({super.key, required this.productBloc, this.posKey});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: productBloc,
      child: _PosView(key: posKey),
    );
  }
}

class _PosView extends StatefulWidget {
  const _PosView({super.key});
  @override
  State<_PosView> createState() => _PosViewState();
}

class _PosViewState extends State<_PosView> {
  final _searchCtrl = TextEditingController();
  final _scrollController = ScrollController();
  int? _categoryId;
  List<Bundle> _bundles = [];
  int _draftCountKey = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadBundles();
  }

  void reloadBundles() {
    _loadBundles();
  }

  void _refreshDraftCount() {
    setState(() {
      _draftCountKey = DateTime.now().millisecondsSinceEpoch;
    });
  }

  Future<void> _loadBundles() async {
    try {
      final dao = BundleDao();
      final bundles = await dao.getAll();
      if (mounted)
        setState(() {
          _bundles = bundles;
        });
      debugPrint('_loadBundles: ${bundles.length} bundles loaded');
    } catch (e, s) {
      debugPrint('_loadBundles error: $e\n$s');
    }
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                                    ctx
                                        .read<ProductBloc>()
                                        .add(ProductLoad(categoryId: c.id));
                                  },
                                )),
                          ],
                        ),
                      ),
                    Expanded(
                      child: state.products.isEmpty && _bundles.isEmpty
                          ? _EmptyProduct()
                          : LayoutBuilder(
                              builder: (ctx, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount = compact
                                    ? (width > 800 ? 6 : 5)
                                    : (width > 800
                                        ? 5
                                        : width > 600
                                            ? 4
                                            : 3);
                                final totalItems = state.products.length +
                                    _bundles.length +
                                    (state.hasMore ? 1 : 0);
                                return GridView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.all(compact ? 4 : 8),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: compact ? 0.65 : 0.75,
                                    crossAxisSpacing: compact ? 4 : 8,
                                    mainAxisSpacing: compact ? 4 : 8,
                                  ),
                                  itemCount: totalItems,
                                  itemBuilder: (_, i) {
                                    if (i < state.products.length) {
                                      final p = state.products[i];
                                      return _ProductCard(
                                          product: p, compact: compact);
                                    }
                                    final bundleIdx = i - state.products.length;
                                    if (bundleIdx < _bundles.length) {
                                      return _BundleCard(
                                        bundle: _bundles[bundleIdx],
                                        compact: compact,
                                      );
                                    }
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
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
    return BlocBuilder<CartBloc, CartState>(
      builder: (ctx, cart) {
        return Row(
          children: [
            // Column 1: Products
            Expanded(
              flex: 3,
              child: _buildProductArea(compact: true),
            ),
            Container(width: 1, color: Colors.grey[300]),
            // Column 2: Customer, Table, Note
            Expanded(
              flex: 2,
              child: _buildSelectionPanel(ctx, cart),
            ),
            Container(width: 1, color: Colors.grey[300]),
            // Column 3: Cart
            Expanded(
              flex: 3,
              child: _buildCartSidebar(ctx, cart),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSelectionPanel(BuildContext ctx, CartState cart) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Customer section
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            width: double.infinity,
            child: const Text('Pelanggan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          _buildCustomerBar(ctx, cart),
          const Divider(height: 1),
          // Table section
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            width: double.infinity,
            child: const Text('Meja / Pickup',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          _buildTableBar(ctx, cart),
          const Divider(height: 1),
          // Note section
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[100],
            width: double.infinity,
            child: const Text('Catatan',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
          _buildNoteBar(ctx, cart),
        ],
      ),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
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
                                    ctx
                                        .read<ProductBloc>()
                                        .add(ProductLoad(categoryId: c.id));
                                  },
                                )),
                          ],
                        ),
                      ),
                    Expanded(
                      child: state.products.isEmpty && _bundles.isEmpty
                          ? const _EmptyProduct()
                          : LayoutBuilder(
                              builder: (ctx, constraints) {
                                final width = constraints.maxWidth;
                                final crossAxisCount = width > 800
                                    ? 5
                                    : width > 600
                                        ? 4
                                        : 3;
                                final totalItems = state.products.length +
                                    _bundles.length +
                                    (state.hasMore ? 1 : 0);
                                return GridView.builder(
                                  controller: _scrollController,
                                  padding: const EdgeInsets.all(8),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: crossAxisCount,
                                    childAspectRatio: 0.75,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                  ),
                                  itemCount: totalItems,
                                  itemBuilder: (_, i) {
                                    if (i < state.products.length) {
                                      final p = state.products[i];
                                      return _ProductCard(product: p);
                                    }
                                    final bundleIdx = i - state.products.length;
                                    if (bundleIdx < _bundles.length) {
                                      return _BundleCard(
                                        bundle: _bundles[bundleIdx],
                                      );
                                    }
                                    return const Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16),
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
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
            final fmt = NumberFormat.currency(
                locale: 'id', symbol: 'Rp ', decimalDigits: 0);
            return Container(
              color: Theme.of(ctx).primaryColor,
              margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text('${cart.itemCount} item',
                      style: const TextStyle(color: Colors.white)),
                  const Spacer(),
                  Text(fmt.format(cart.total),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.white),
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
                  fontWeight: cart.customer != null
                      ? FontWeight.bold
                      : FontWeight.normal,
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

  void _showTablePicker(BuildContext ctx) async {
    final tables = await TableDao().getActive();
    if (!ctx.mounted) return;
    showConstrainedModalBottomSheet(
      context: ctx,
      builder: (_) => _TablePickerSheet(
        tables: tables,
        onSelected: (table) {
          ctx.read<CartBloc>().add(CartSetTable(table));
          Navigator.pop(ctx);
        },
      ),
    );
  }

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
    _refreshDraftCount();
  }

  Widget _buildTableBar(BuildContext ctx, CartState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              const Icon(Icons.table_restaurant, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  state.table?.name ?? 'Meja (opsional)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: state.table != null
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: state.table != null ? null : Colors.grey,
                  ),
                ),
              ),
              if (state.table != null)
                GestureDetector(
                  onTap: () => ctx.read<CartBloc>().add(CartSetTable(null)),
                  child: const Icon(Icons.close, size: 16),
                )
              else
                TextButton(
                  onPressed: () => _showTablePicker(ctx),
                  child: const Text('Pilih', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoteBar(BuildContext ctx, CartState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            const Icon(Icons.note, size: 18),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                state.note ?? 'Catatan (opsional)',
                style: TextStyle(
                  fontSize: 12,
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
              child: Text(
                state.note != null ? 'Edit' : 'Tambah',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            if (state.note != null)
              GestureDetector(
                onTap: () => ctx.read<CartBloc>().add(CartSetNote(null)),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartSidebar(BuildContext ctx, CartState cart) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
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
              FutureBuilder<int>(
                key: ValueKey(_draftCountKey),
                future: OrderDao().getDraftOrders().then((l) => l.length),
                builder: (_, snap) {
                  final count = snap.data ?? 0;
                  return Badge(
                    isLabelVisible: count > 0,
                    label: Text('$count'),
                    child: IconButton(
                      icon: const Icon(Icons.inbox, color: Colors.white),
                      tooltip: 'Ambil Draft',
                      onPressed: () => _pickupDraft(ctx),
                    ),
                  );
                },
              ),
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
                        child: Icon(Icons.shopping_cart_outlined,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 8),
                      Text('Keranjang kosong',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(8),
                  children: _buildCartItemList(ctx, cart.items),
                ),
        ),
        // Summary
        if (cart.items.isNotEmpty)
          Container(
            margin: EdgeInsets.only(bottom: MediaQuery.of(ctx).padding.bottom + 64),
            decoration: BoxDecoration(
              color: Theme.of(ctx).cardColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Discount input
                Row(
                  children: [
                    const Text('Diskon', style: TextStyle(fontSize: 13)),
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
                                disc > 0
                                    ? Discount(
                                        type: DiscountType.nominal,
                                        value: disc.toDouble())
                                    : null,
                              ));
                        },
                      ),
                    ),
                  ],
                ),
                const Divider(),
                // Simpan Draft
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed:
                        cart.items.isEmpty ? null : () => _saveDraft(ctx),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Simpan Draft'),
                  ),
                ),
                const SizedBox(height: 8),
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
  }

  void _showCartItemOptions(BuildContext context, dynamic item) {
    showConstrainedModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.remove_circle_outline, color: Colors.red),
            title: Text(item.bundleName != null
                ? 'Hapus Semua dari Bundling'
                : 'Hapus'),
            onTap: () {
              if (item.bundleId != null) {
                // Remove all bundle items
                final cartState = context.read<CartBloc>().state;
                for (final ci in cartState.items) {
                  if (ci.bundleId == item.bundleId) {
                    context.read<CartBloc>().add(CartRemoveItem(ci.cartKey));
                  }
                }
              } else {
                context.read<CartBloc>().add(CartRemoveItem(item.cartKey));
              }
              Navigator.pop(ctx);
            },
          ),
          if (item.bundleId == null)
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

  List<Widget> _buildCartItemList(BuildContext ctx, List<CartItem> items) {
    final list = <Widget>[];
    int i = 0;
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    while (i < items.length) {
      if (items[i].bundleId != null) {
        final bundleId = items[i].bundleId;
        final bundleName = items[i].bundleName!;
        final group = <CartItem>[];
        while (i < items.length && items[i].bundleId == bundleId) {
          group.add(items[i]);
          i++;
        }
        final total = group.fold<double>(0, (s, ci) => s + ci.subtotal);
        final instances = group.map((ci) => ci.qty).reduce(_gcd);
        final bundlePrice = total / instances;
        list.add(Card(
          margin: const EdgeInsets.only(bottom: 4),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.redeem, size: 16, color: Colors.orange),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(bundleName,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.orange))),
              ]),
              const SizedBox(height: 4),
              ...group.map((ci) => Padding(
                    padding: const EdgeInsets.only(left: 22),
                    child: Text('${ci.qty ~/ instances}x ${ci.product.name}',
                        style: const TextStyle(fontSize: 12)),
                  )),
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text('${instances}x ${fmt.format(bundlePrice)}',
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600)),
              ),
              const Divider(height: 8),
              Row(children: [
                const Spacer(),
                Text(fmt.format(total),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13)),
              ]),
            ]),
          ),
        ));
      } else {
        final item = items[i];
        i++;
        list.add(Card(
          child: ListTile(
            dense: true,
            leading: SizedBox(
              width: 24,
              height: 24,
              child: Center(
                  child: Text('${item.qty}x',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Theme.of(ctx).primaryColor))),
            ),
            title:
                Text(item.product.name, style: const TextStyle(fontSize: 13)),
            subtitle: item.variant != null
                ? Text(item.variant!.name,
                    style: const TextStyle(fontSize: 11, color: Colors.grey))
                : null,
            trailing: SizedBox(
              width: 90,
              child: Text(fmt.format(item.subtotal),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            onTap: () => _showCartItemOptions(ctx, item),
          ),
        ));
      }
    }
    return list;
  }

  Widget _buildCartItemTile(BuildContext ctx, CartItem item) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    if (item.bundleId != null) {
      // This won't be called for bundle items - handled in _buildCartItemList
      return const SizedBox.shrink();
    }
    return Card(
      child: ListTile(
        dense: true,
        leading: SizedBox(
          width: 24,
          height: 24,
          child: Center(
              child: Text('${item.qty}x',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Theme.of(ctx).primaryColor))),
        ),
        title: Text(item.product.name, style: const TextStyle(fontSize: 13)),
        subtitle: item.variant != null
            ? Text(item.variant!.name,
                style: const TextStyle(fontSize: 11, color: Colors.grey))
            : null,
        trailing: SizedBox(
          width: 90,
          child: Text(fmt.format(item.subtotal),
              textAlign: TextAlign.right,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        ),
        onTap: () => _showCartItemOptions(ctx, item),
      ),
    );
  }
}

void _showVariantPicker(BuildContext context, dynamic product) {
  final fmt =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
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
                    context
                        .read<CartBloc>()
                        .add(CartAddItem(product, variant: v));
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
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return GestureDetector(
      onTap: () {
        if (ReceiptSettings.manageStock && product.stock <= 0) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Stok habis!')));
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
                          errorBuilder: (_, __, ___) => _ProductInitial(
                              name: product.name,
                              outOfStock: ReceiptSettings.manageStock &&
                                  product.stock <= 0),
                        )
                      : _ProductInitial(
                          name: product.name,
                          outOfStock: ReceiptSettings.manageStock &&
                              product.stock <= 0),
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
                    color: Theme.of(context).primaryColor),
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

class _BundleCard extends StatelessWidget {
  final Bundle bundle;
  final bool compact;
  const _BundleCard({required this.bundle, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final fmt =
        NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return GestureDetector(
      onTap: () => _showBundleDetail(context, bundle),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(compact ? 4 : 8),
          side: BorderSide(
            color: Colors.orange.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 4 : 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(compact ? 4 : 8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.redeem,
                        size: compact ? 20 : 28,
                        color: Colors.orange,
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        'BUNDLING',
                        style: TextStyle(
                          fontSize: compact ? 8 : 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: compact ? 2 : 4),
              Text(
                bundle.name.length > (compact ? 15 : 20)
                    ? '${bundle.name.substring(0, compact ? 12 : 17)}...'
                    : bundle.name,
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
              SizedBox(height: compact ? 1 : 2),
              Text(
                fmt.format(bundle.price),
                style: TextStyle(
                  fontSize: compact ? 10 : 12,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
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

void _showBundleDetail(BuildContext context, Bundle bundle) async {
  final dao = BundleDao();
  final items = await dao.getItems(bundle.id!);
  if (!context.mounted) return;
  final fmt =
      NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
  showConstrainedDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.redeem, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
              child: Text(bundle.name,
                  style: const TextStyle(fontSize: 16))),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Harga Bundling: ${fmt.format(bundle.price)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green)),
            const SizedBox(height: 10),
            ...items.where((i) => i.product != null).map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Text('${i.qty} x ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13)),
                      Expanded(
                          child: Text(i.product!.name,
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
          ],
        ),
      ),
      actions: [
        OverflowBar(
          alignment: MainAxisAlignment.end,
          overflowAlignment: OverflowBarAlignment.end,
          children: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                context.read<CartBloc>().add(CartAddBundle(bundle, items));
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('${bundle.name} ditambahkan'),
                  duration: const Duration(milliseconds: 500),
                ));
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ],
    ),
  );
}

class _EmptyProduct extends StatelessWidget {
  const _EmptyProduct();

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 160;
        return Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: compact ? 36 : 72,
                  color: color.withValues(alpha: 0.5),
                ),
                SizedBox(height: compact ? 6 : 16),
                Text(
                  'Belum ada produk',
                  style: TextStyle(fontSize: compact ? 14 : 16, color: color),
                ),
                if (!compact) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Tambahkan produk melalui menu Pengaturan',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ProductInitial extends StatelessWidget {
  final String name;
  final bool outOfStock;
  const _ProductInitial({required this.name, this.outOfStock = false});

  Color _colorFromName(String name) {
    const colors = [
      Colors.blue,
      Colors.teal,
      Colors.purple,
      Colors.indigo,
      Colors.orange,
      Colors.pink,
      Colors.cyan,
      Colors.green,
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
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Pilih Meja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari meja...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onChanged: _filter,
              ),
              const SizedBox(height: 12),
              if (_filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Tidak ada meja',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: GridView.builder(
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
                              Text(
                                t.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${t.capacity} kursi',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (t.note != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  t.note!,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
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

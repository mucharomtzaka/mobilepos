import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../core/database/transaction_dao.dart';
import '../../../core/models/transaction.dart';
import '../../../core/utils/responsive_dialog.dart';
import '../../shift/bloc/shift_bloc.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final _dao = TransactionDao();
  List<Transaction> _list = [];
  bool _loading = true;
  double _total = 0;
  String? _shiftStart;

  final _categories = ['Penjualan', 'Investasi', 'Pinjaman', 'Lainnya'];

  static const int _pageSize = 20;
  int _offset = 0;
  bool _hasMore = true;
  bool _loadingMore = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    final shiftState = context.read<ShiftBloc>().state;
    if (shiftState is ShiftOpen) {
      _shiftStart = shiftState.shift.startTime;
    }
    _load();
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
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _offset = 0;
    _hasMore = true;
    final list = await _dao.getAllPaginated(
      type: 'income',
      startDate: _shiftStart,
      limit: _pageSize,
      offset: 0,
    );
    final total = await _dao.getTotal(type: 'income', startDate: _shiftStart);
    if (mounted) {
      setState(() {
        _list = list;
        _total = total;
        _loading = false;
        _hasMore = list.length == _pageSize;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _offset += _pageSize;
    final list = await _dao.getAllPaginated(
      type: 'income',
      startDate: _shiftStart,
      limit: _pageSize,
      offset: _offset,
    );
    if (mounted) {
      setState(() {
        _list.addAll(list);
        _loadingMore = false;
        _hasMore = list.length == _pageSize;
      });
    }
  }

  Future<void> _showForm([Transaction? existing]) async {
    final amountFmt = NumberFormat('#,###', 'id_ID');
    final amountCtrl = TextEditingController(
      text: existing != null ? amountFmt.format(existing.amount.toInt()) : '',
    );
    final descCtrl =
        TextEditingController(text: existing?.description ?? '');
    String category = existing?.category ?? _categories.first;
    final formKey = GlobalKey<FormState>();

    void formatAmount() {
      final text = amountCtrl.text.replaceAll('.', '');
      if (text.isEmpty) return;
      final parsed = int.tryParse(text);
      if (parsed == null) return;
      final formatted = amountFmt.format(parsed);
      if (amountCtrl.text != formatted) {
        amountCtrl.value = TextEditingValue(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    }

    amountCtrl.addListener(formatAmount);

    final saved = await showConstrainedDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing != null ? 'Edit Pemasukan' : 'Tambah Pemasukan'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _categories.contains(category) ? category : 'Lainnya',
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => category = v!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah (Rp)',
                      prefixIcon: Icon(Icons.money),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Masukkan jumlah';
                      final raw = v.replaceAll('.', '');
                      if (double.tryParse(raw) == null || double.parse(raw) <= 0) {
                        return 'Jumlah tidak valid';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Keterangan (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                amountCtrl.removeListener(formatAmount);
                Navigator.pop(ctx);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final now = DateTime.now();
                final t = Transaction(
                  id: existing?.id,
                  type: 'income',
                  category: category,
                  amount: double.parse(amountCtrl.text.replaceAll('.', '')),
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  createdAt: existing?.createdAt ?? now.toIso8601String(),
                );
                if (existing != null) {
                  await _dao.update(t);
                } else {
                  await _dao.insert(t);
                }
                amountCtrl.removeListener(formatAmount);
                if (ctx.mounted) Navigator.pop(ctx, true);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    if (saved == true) _load();
  }

  Future<void> _delete(Transaction t) async {
    final ok = await showConstrainedDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus'),
        content: Text('Hapus pemasukan "${t.category}" sebesar Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(t.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _dao.delete(t.id!);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemasukan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showForm(),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: Colors.green.withValues(alpha: 0.1),
                  child: Text(
                    'Total: ${fmt.format(_total)}',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_shiftStart != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                    child: Text(
                      'Menampilkan data shift aktif',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                Expanded(
                  child: _list.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.trending_up, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                              const SizedBox(height: 8),
                              Text('Belum ada pemasukan', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: _list.length + (_hasMore ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i >= _list.length) {
                                return const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: Center(child: CircularProgressIndicator()),
                                );
                              }
                              final t = _list[i];
                              return Card(
                                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.green.withValues(alpha: 0.15),
                                    child: const Icon(Icons.trending_up,
                                        color: Colors.green),
                                  ),
                                  title: Text(t.category),
                                  subtitle: Text(
                                    '${t.description ?? ''}${t.description != null ? ' • ' : ''}${DateFormat('dd/MM/yyyy').format(DateTime.parse(t.createdAt))}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: Text(
                                    fmt.format(t.amount),
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green),
                                  ),
                                  onTap: () => _showForm(t),
                                  onLongPress: () => _delete(t),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/shift_bloc.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../../core/models/user.dart';
import '../../../core/utils/responsive_dialog.dart';
import '../../../core/utils/responsive_page_insets.dart';

class ShiftPage extends StatelessWidget {
  const ShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return const SizedBox();
    context.read<ShiftBloc>().add(ShiftCheck(authState.user.id!));

    return Scaffold(
      appBar: AppBar(title: const Text('Shift Kasir')),
      body: BlocBuilder<ShiftBloc, ShiftState>(
        builder: (ctx, state) {
          if (state is ShiftLoading || state is ShiftInitial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ShiftOpen) {
            return _OpenShiftView(state: state);
          }
          if (state is ShiftClosed) {
            return _OpenShiftForm(user: authState.user);
          }
          return const SizedBox();
        },
      ),
    );
  }
}

class _OpenShiftView extends StatelessWidget {
  final ShiftOpen state;
  const _OpenShiftView({required this.state});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
    final ctrl = TextEditingController();

    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: ResponsivePageInsets.content(
        context,
        maxContentWidth: 640,
        top: 16,
        bottom: 16 + bottomPad,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_open, color: Colors.green),
              title: const Text('Shift Sedang Berjalan',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                  'Dibuka: ${dateFmt.format(DateTime.parse(state.shift.startTime))}\n'
                  'Modal: ${fmt.format(state.shift.openingCash)}'),
              isThreeLine: true,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
              icon: const Icon(Icons.lock),
              label: const Text('Tutup Shift'),
              onPressed: () => _showCloseDialog(context, ctrl),
            ),
          ),
        ],
      ),
    );
  }

  void _showCloseDialog(BuildContext ctx, TextEditingController ctrl) {
    final fmt = NumberFormat('#,###', 'id_ID');

    void formatCurrency() {
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
      builder: (_) => AlertDialog(
        title: const Text('Tutup Shift'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
              labelText: 'Uang di Laci',
              border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
              onPressed: () {
                ctrl.removeListener(formatCurrency);
                Navigator.pop(ctx);
              },
              child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              final cash =
                  double.tryParse(ctrl.text.replaceAll('.', '')) ?? 0;
              ctx.read<ShiftBloc>().add(
                  ShiftCloseEvent(state.shift.id!, cash));
              ctrl.removeListener(formatCurrency);
              Navigator.pop(ctx);
            },
            child: const Text('Tutup Shift'),
          ),
        ],
      ),
    );
  }
}

class _OpenShiftForm extends StatefulWidget {
  final User user;
  const _OpenShiftForm({required this.user});

  @override
  State<_OpenShiftForm> createState() => _OpenShiftFormState();
}

class _OpenShiftFormState extends State<_OpenShiftForm> {
  late final TextEditingController _ctrl;
  late final NumberFormat _fmt;

  @override
  void initState() {
    super.initState();
    _fmt = NumberFormat('#,###', 'id_ID');
    _ctrl = TextEditingController();
    _ctrl.addListener(_formatCurrency);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_formatCurrency);
    _ctrl.dispose();
    super.dispose();
  }

  void _formatCurrency() {
    final text = _ctrl.text.replaceAll('.', '');
    if (text.isEmpty) return;
    final parsed = int.tryParse(text);
    if (parsed == null) return;
    final formatted = _fmt.format(parsed);
    if (_ctrl.text != formatted) {
      _ctrl.value = TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: ResponsivePageInsets.content(
        context,
        maxContentWidth: 640,
        top: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.lock, size: 64, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          const Text('Tidak ada shift aktif',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18)),
          const Text('Buka shift untuk mulai transaksi',
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Text('Kasir: ${widget.user.name}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Modal Awal (Uang di Laci)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.lock_open),
              label: const Text('Buka Shift'),
              onPressed: () {
                final cash =
                    double.tryParse(_ctrl.text.replaceAll('.', '')) ?? 0;
                context
                    .read<ShiftBloc>()
                    .add(ShiftOpenEvent(widget.user.id!, cash));
              },
            ),
          ),
        ],
      ),
    );
  }
}

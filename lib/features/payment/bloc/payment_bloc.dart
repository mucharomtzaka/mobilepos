import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/order.dart';
import '../../../core/models/transaction.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/database/transaction_dao.dart';
import '../../../core/database/stock_dao.dart';
import '../../../core/models/stock_movement.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/utils/receipt_settings.dart';
import '../../cart/bloc/cart_bloc.dart';

// Events
abstract class PaymentEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentAddEntry extends PaymentEvent {
  final PaymentEntry entry;
  PaymentAddEntry(this.entry);
}

class PaymentRemoveEntry extends PaymentEvent {
  final int index;
  PaymentRemoveEntry(this.index);
}

class PaymentConfirm extends PaymentEvent {
  final CartState cartState;
  final int userId;
  final int? shiftId;
  final int? customerId;
  final int? tableId;
  final String? note;
  PaymentConfirm({
    required this.cartState,
    required this.userId,
    this.shiftId,
    this.customerId,
    this.tableId,
    this.note,
  });
}

class PaymentReset extends PaymentEvent {}

// States
abstract class PaymentState extends Equatable {
  @override
  List<Object?> get props => [];
}

class PaymentIdle extends PaymentState {
  final List<PaymentEntry> entries;
  PaymentIdle([this.entries = const []]);
  @override
  List<Object?> get props => [entries];

  double get totalPaid => entries.fold(0, (s, e) => s + e.amount);
}

class PaymentProcessing extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final Order order;
  final double change;
  PaymentSuccess(this.order, this.change);
  @override
  List<Object?> get props => [order];
}

class PaymentFailure extends PaymentState {
  final String message;
  PaymentFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final OrderDao _orderDao;
  final StockDao _stockDao;

  PaymentBloc(this._orderDao, this._stockDao) : super(PaymentIdle()) {
    on<PaymentAddEntry>(_onAdd);
    on<PaymentRemoveEntry>(_onRemove);
    on<PaymentConfirm>(_onConfirm);
    on<PaymentReset>(_onReset);
  }

  void _onAdd(PaymentAddEntry e, Emitter<PaymentState> emit) {
    final current = state is PaymentIdle
        ? List<PaymentEntry>.from((state as PaymentIdle).entries)
        : <PaymentEntry>[];
    current.add(e.entry);
    emit(PaymentIdle(current));
  }

  void _onRemove(PaymentRemoveEntry e, Emitter<PaymentState> emit) {
    final current = state is PaymentIdle
        ? List<PaymentEntry>.from((state as PaymentIdle).entries)
        : <PaymentEntry>[];
    current.removeAt(e.index);
    emit(PaymentIdle(current));
  }

  Future<void> _onConfirm(PaymentConfirm e, Emitter<PaymentState> emit) async {
    final entries = state is PaymentIdle
        ? (state as PaymentIdle).entries
        : <PaymentEntry>[];
    emit(PaymentProcessing());
    try {
      final cart = e.cartState;
      final now = DateTime.now();
      final orderNumber =
          'ORD${now.millisecondsSinceEpoch}';
      final totalPaid = entries.fold(0.0, (s, e) => s + e.amount);
      final change = totalPaid - cart.total;

      final order = Order(
        orderNumber: orderNumber,
        shiftId: e.shiftId,
        userId: e.userId,
        customerId: e.customerId,
        tableId: e.tableId,
        note: e.note,
        subtotal: cart.subtotal,
        discountAmount: cart.discountAmount,
        discountType: cart.discount?.type.name,
        discountValue: cart.discount?.value ?? 0,
        taxPercent: cart.taxPercent,
        taxAmount: cart.taxAmount,
        total: cart.total,
        totalPaid: totalPaid,
        change: change,
        createdAt: now.toIso8601String(),
      );

      final orderId = await _orderDao.insertOrder(order);
      final items = cart.items
          .map((i) => OrderItem(
                orderId: orderId,
                productId: i.product.id!,
                productName: i.product.name,
                variantName: i.variant?.name,
                price: i.effectivePrice,
                qty: i.qty,
                subtotal: i.subtotal,
                bundleName: i.bundleName,
              ))
          .toList();
      await _orderDao.insertItems(items);

      await _orderDao.insertPayments(orderId, entries);

      // Check & decrease stock
      if (ReceiptSettings.manageStock) {
        for (final item in cart.items) {
          final currentStock = await _getProductStock(item.product.id!);
          if (currentStock < item.qty) {
            throw Exception(
                'Stok ${item.product.name} tidak mencukupi (stok: $currentStock, dibutuhkan: ${item.qty})');
          }
          await _stockDao.addMovement(StockMovement(
            productId: item.product.id!,
            type: 'out',
            qty: item.qty,
            note: 'Order $orderNumber',
            createdAt: now.toIso8601String(),
          ));
        }
      }

      // Record sale as income transaction for cashflow report
      await TransactionDao().insert(Transaction(
        type: 'income',
        category: 'Penjualan',
        amount: cart.total,
        description: 'Penjualan $orderNumber',
        createdAt: now.toIso8601String(),
      ));

      // Delete draft if loaded from draft
      if (cart.draftOrderId != null) {
        await _orderDao.deleteDraftOrder(cart.draftOrderId!);
      }

      emit(PaymentSuccess(
        order.copyWith(id: orderId),
        change,
      ));
    } catch (e) {
      emit(PaymentFailure(e.toString()));
    }
  }

  void _onReset(PaymentReset e, Emitter<PaymentState> emit) {
    emit(PaymentIdle());
  }

  Future<int> _getProductStock(int productId) async {
    final db = await DatabaseHelper.instance.db;
    final result = await db.rawQuery(
        'SELECT stock FROM products WHERE id = ?', [productId]);
    if (result.isEmpty) return 0;
    return (result.first['stock'] as int?) ?? 0;
  }
}

extension _OrderCopyWith on Order {
  Order copyWith({int? id, double? totalPaid, double? change}) => Order(
        id: id ?? this.id,
        orderNumber: orderNumber,
        shiftId: shiftId,
        userId: userId,
        subtotal: subtotal,
        discountAmount: discountAmount,
        discountType: discountType,
        discountValue: discountValue,
        taxPercent: taxPercent,
        taxAmount: taxAmount,
        total: total,
        totalPaid: totalPaid ?? this.totalPaid,
        change: change ?? this.change,
        status: status,
        note: note,
        createdAt: createdAt,
      );
}

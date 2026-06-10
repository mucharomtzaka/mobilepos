import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/order_dao.dart';
import '../../../core/database/product_dao.dart';
import '../../../core/database/customer_dao.dart';
import '../../../core/models/cart_item.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/order.dart';
import '../../../core/models/table.dart';
import '../../../core/database/table_dao.dart';
import '../../../core/models/product.dart';
import '../../../core/models/product_variant.dart';
import '../../../core/models/bundle.dart';
import '../../../core/models/bundle_item.dart';

// Events
abstract class CartEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CartAddItem extends CartEvent {
  final Product product;
  final ProductVariant? variant;
  CartAddItem(this.product, {this.variant});
}

class CartAddBundle extends CartEvent {
  final Bundle bundle;
  final List<BundleItem> items;
  CartAddBundle(this.bundle, this.items);
}

class CartRemoveItem extends CartEvent {
  final String cartKey;
  CartRemoveItem(this.cartKey);
}

class CartUpdateQty extends CartEvent {
  final String cartKey;
  final int qty;
  CartUpdateQty(this.cartKey, this.qty);
}

class CartApplyDiscount extends CartEvent {
  final Discount? discount;
  CartApplyDiscount(this.discount);
}

class CartSetTaxPercent extends CartEvent {
  final double percent;
  CartSetTaxPercent(this.percent);
}

class CartSetCustomer extends CartEvent {
  final Customer? customer;
  CartSetCustomer(this.customer);
}

class CartSetTable extends CartEvent {
  final RestoTable? table;
  CartSetTable(this.table);
}

class CartSetNote extends CartEvent {
  final String? note;
  CartSetNote(this.note);
}

class CartClear extends CartEvent {}

class CartSaveDraft extends CartEvent {
  final int userId;
  final int? shiftId;
  CartSaveDraft({required this.userId, this.shiftId});
}

class CartLoadDraft extends CartEvent {
  final Order order;
  final List<OrderItem> items;
  CartLoadDraft({required this.order, required this.items});
}

// State
class CartState extends Equatable {
  final List<CartItem> items;
  final Discount? discount;
  final double taxPercent;
  final Customer? customer;
  final int? draftOrderId;
  final RestoTable? table;
  final String? note;

  const CartState({this.items = const [], this.discount, this.taxPercent = 0, this.customer, this.draftOrderId, this.table, this.note});

  double get subtotal =>
      items.fold(0, (sum, i) => sum + i.subtotal);

  double get discountAmount =>
      discount?.calculate(subtotal) ?? 0;

  double get taxBase => subtotal - discountAmount;

  double get taxAmount => taxBase * taxPercent / 100;

  double get total => taxBase + taxAmount;

  int get itemCount {
    final regular = items.where((i) => i.bundleId == null).fold(0, (sum, i) => sum + i.qty);
    final bundles = items.where((i) => i.bundleId != null).map((i) => i.bundleId).toSet().length;
    return regular + bundles;
  }

  CartState copyWith({List<CartItem>? items, Discount? discount, bool clearDiscount = false, double? taxPercent, Customer? customer, bool clearCustomer = false, int? draftOrderId, bool clearDraftOrderId = false, RestoTable? table, bool clearTable = false, String? note, bool clearNote = false}) =>
      CartState(
        items: items ?? this.items,
        discount: clearDiscount ? null : (discount ?? this.discount),
        taxPercent: taxPercent ?? this.taxPercent,
        customer: clearCustomer ? null : (customer ?? this.customer),
        draftOrderId: clearDraftOrderId ? null : (draftOrderId ?? this.draftOrderId),
        table: clearTable ? null : (table ?? this.table),
        note: clearNote ? null : (note ?? this.note),
      );

  @override
  List<Object?> get props => [items, discount, taxPercent, customer, draftOrderId, table, note];
}

// BLoC
class CartBloc extends Bloc<CartEvent, CartState> {
  final OrderDao _orderDao;
  final ProductDao _productDao;
  final CustomerDao _customerDao;

  CartBloc(this._orderDao, this._productDao, this._customerDao) : super(const CartState()) {
    on<CartAddItem>(_onAdd);
    on<CartAddBundle>(_onAddBundle);
    on<CartRemoveItem>(_onRemove);
    on<CartUpdateQty>(_onUpdateQty);
    on<CartApplyDiscount>(_onDiscount);
    on<CartSetTaxPercent>(_onSetTax);
    on<CartSetCustomer>(_onSetCustomer);
    on<CartSetTable>(_onSetTable);
    on<CartSetNote>(_onSetNote);
    on<CartClear>(_onClear);
    on<CartSaveDraft>(_onSaveDraft);
    on<CartLoadDraft>(_onLoadDraft);
  }

  void _onSetTax(CartSetTaxPercent e, Emitter<CartState> emit) {
    emit(state.copyWith(taxPercent: e.percent));
  }

  void _onSetCustomer(CartSetCustomer e, Emitter<CartState> emit) {
    emit(state.copyWith(customer: e.customer, clearCustomer: e.customer == null));
  }

  void _onSetTable(CartSetTable e, Emitter<CartState> emit) {
    emit(state.copyWith(table: e.table, clearTable: e.table == null));
  }

  void _onSetNote(CartSetNote e, Emitter<CartState> emit) {
    emit(state.copyWith(note: e.note, clearNote: e.note == null));
  }

  void _onAdd(CartAddItem e, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final key = CartItem(product: e.product, variant: e.variant).cartKey;
    final idx = items.indexWhere((i) => i.cartKey == key);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(qty: items[idx].qty + 1);
    } else {
      items.add(CartItem(product: e.product, variant: e.variant));
    }
    emit(state.copyWith(items: items));
  }

  void _onAddBundle(CartAddBundle e, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final totalNormal = e.items.fold<double>(
      0,
      (sum, bi) => sum + (bi.product!.price * bi.qty),
    );
    for (final bi in e.items) {
      if (bi.product == null) continue;
      final adjustedPrice = totalNormal > 0
          ? ((e.bundle.price * (bi.product!.price * bi.qty) / totalNormal) / bi.qty).toDouble()
          : 0.0;
      final key = CartItem(
        product: bi.product!,
        bundleId: e.bundle.id,
        bundleName: e.bundle.name,
      ).cartKey;
      final idx = items.indexWhere((i) => i.cartKey == key);
      if (idx >= 0) {
        items[idx] = items[idx].copyWith(qty: items[idx].qty + bi.qty);
      } else {
        items.add(CartItem(
          product: bi.product!,
          qty: bi.qty,
          bundleId: e.bundle.id,
          bundleName: e.bundle.name,
          bundleAdjustedPrice: adjustedPrice,
        ));
      }
    }
    emit(state.copyWith(items: items));
  }

  void _onRemove(CartRemoveItem e, Emitter<CartState> emit) {
    final items =
        state.items.where((i) => i.cartKey != e.cartKey).toList();
    emit(state.copyWith(items: items));
  }

  void _onUpdateQty(CartUpdateQty e, Emitter<CartState> emit) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.cartKey == e.cartKey);
    if (idx >= 0) {
      if (e.qty <= 0) {
        items.removeAt(idx);
      } else {
        items[idx] = items[idx].copyWith(qty: e.qty);
      }
    }
    emit(state.copyWith(items: items));
  }

  void _onDiscount(CartApplyDiscount e, Emitter<CartState> emit) {
    emit(state.copyWith(
        discount: e.discount, clearDiscount: e.discount == null));
  }

  void _onClear(CartClear e, Emitter<CartState> emit) {
    emit(CartState(taxPercent: state.taxPercent, draftOrderId: null, table: null, note: null));
  }

  Future<void> _onSaveDraft(CartSaveDraft e, Emitter<CartState> emit) async {
    try {
      final now = DateTime.now();
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
                bundleId: i.bundleId,
                bundleAdjustedPrice: i.bundleAdjustedPrice,
              ))
          .toList();
      
      // If existing draft, update it
      if (state.draftOrderId != null) {
        final order = Order(
          id: state.draftOrderId,
          orderNumber: 'DRF${now.millisecondsSinceEpoch}',
          userId: e.userId,
          shiftId: e.shiftId,
          customerId: state.customer?.id,
          tableId: state.table?.id,
          note: state.note,
          subtotal: state.subtotal,
          discountAmount: state.discountAmount,
          discountType: state.discount?.type.name,
          discountValue: state.discount?.value ?? 0,
          taxPercent: state.taxPercent,
          taxAmount: state.taxAmount,
          total: state.total,
          createdAt: now.toIso8601String(),
        );
        await _orderDao.updateDraftOrder(state.draftOrderId!, order, items);
        emit(CartState(taxPercent: state.taxPercent));
      } else {
        // New draft
        final order = Order(
          orderNumber: 'DRF${now.millisecondsSinceEpoch}',
          userId: e.userId,
          shiftId: e.shiftId,
          customerId: state.customer?.id,
          tableId: state.table?.id,
          note: state.note,
          subtotal: state.subtotal,
          discountAmount: state.discountAmount,
          discountType: state.discount?.type.name,
          discountValue: state.discount?.value ?? 0,
          taxPercent: state.taxPercent,
          taxAmount: state.taxAmount,
          total: state.total,
          createdAt: now.toIso8601String(),
        );
        await _orderDao.insertDraftOrder(order, items);
        emit(CartState(taxPercent: state.taxPercent));
      }
    } catch (err) {
      debugPrint('Error saving draft: $err');
    }
  }

  Future<void> _onLoadDraft(CartLoadDraft e, Emitter<CartState> emit) async {
    try {
      final cartItems = <CartItem>[];
      for (final oi in e.items) {
        final product = await _productDao.getById(oi.productId);
        if (product == null) continue;
        ProductVariant? variant;
        if (oi.variantName != null) {
          variant = product.variants
              .cast<ProductVariant?>()
              .firstWhere((v) => v?.name == oi.variantName,
                  orElse: () => null);
        }
        cartItems.add(CartItem(
          product: product,
          variant: variant,
          qty: oi.qty,
          bundleId: oi.bundleId,
          bundleName: oi.bundleName,
          bundleAdjustedPrice: oi.bundleAdjustedPrice,
        ));
      }

      // Load discount
      Discount? discount;
      if (e.order.discountValue > 0 && e.order.discountType != null) {
        discount = Discount(
          type: e.order.discountType == 'percent'
              ? DiscountType.percent
              : DiscountType.nominal,
          value: e.order.discountValue,
        );
      }

      // Load table if draft has tableId
      RestoTable? table;
      if (e.order.tableId != null) {
        table = await TableDao().getById(e.order.tableId!);
      }

      // Load customer if draft has customerId
      Customer? customer;
      if (e.order.customerId != null) {
        customer = await _customerDao.getById(e.order.customerId!);
      }

      emit(state.copyWith(
        items: cartItems,
        discount: discount,
        taxPercent: e.order.taxPercent,
        draftOrderId: e.order.id,
        table: table,
        note: e.order.note,
        customer: customer,
      ));
    } catch (err) {
      debugPrint('Error loading draft: $err');
    }
  }
}

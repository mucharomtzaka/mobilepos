import 'package:equatable/equatable.dart';

enum PaymentMethod { tunai, dana, ovo, gopay, transfer, qris }

extension PaymentMethodExt on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.tunai => 'Tunai',
        PaymentMethod.dana => 'DANA',
        PaymentMethod.ovo => 'OVO',
        PaymentMethod.gopay => 'GoPay',
        PaymentMethod.transfer => 'Transfer',
        PaymentMethod.qris => 'QRIS',
      };

  String get value => name;

  static PaymentMethod fromString(String s) =>
      PaymentMethod.values.firstWhere((e) => e.name == s,
          orElse: () => PaymentMethod.tunai);
}

class PaymentEntry extends Equatable {
  final PaymentMethod method;
  final double amount;
  final String? reference;

  const PaymentEntry({
    required this.method,
    required this.amount,
    this.reference,
  });

  @override
  List<Object?> get props => [method, amount];
}

class OrderItem extends Equatable {
  final int? id;
  final int orderId;
  final int productId;
  final String productName;
  final String? variantName;
  final double price;
  final int qty;
  final double subtotal;

  const OrderItem({
    this.id,
    required this.orderId,
    required this.productId,
    required this.productName,
    this.variantName,
    required this.price,
    required this.qty,
    required this.subtotal,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
        id: m['id'],
        orderId: m['order_id'],
        productId: m['product_id'],
        productName: m['product_name'],
        variantName: m['variant_name'],
        price: (m['price'] as num).toDouble(),
        qty: m['qty'],
        subtotal: (m['subtotal'] as num).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'order_id': orderId,
        'product_id': productId,
        'product_name': productName,
        if (variantName != null) 'variant_name': variantName,
        'price': price,
        'qty': qty,
        'subtotal': subtotal,
      };

  String get displayName => variantName != null ? '$productName - $variantName' : productName;

  @override
  List<Object?> get props => [id, productId, variantName, qty];
}

class Order extends Equatable {
  final int? id;
  final String orderNumber;
  final int? shiftId;
  final int userId;
  final int? customerId;
  final int? tableId;
  final double subtotal;
  final double discountAmount;
  final String? discountType;
  final double discountValue;
  final double taxPercent;
  final double taxAmount;
  final double total;
  final double totalPaid;
  final double change;
  final String status;
  final String? note;
  final String createdAt;
  final List<OrderItem> items;
  final List<PaymentEntry> payments;

  const Order({
    this.id,
    required this.orderNumber,
    this.shiftId,
    required this.userId,
    this.customerId,
    this.tableId,
    required this.subtotal,
    this.discountAmount = 0,
    this.discountType,
    this.discountValue = 0,
    this.taxPercent = 0,
    this.taxAmount = 0,
    required this.total,
    this.totalPaid = 0,
    this.change = 0,
    this.status = 'completed',
    this.note,
    required this.createdAt,
    this.items = const [],
    this.payments = const [],
  });

  factory Order.fromMap(Map<String, dynamic> m) => Order(
        id: m['id'],
        orderNumber: m['order_number'],
        shiftId: m['shift_id'],
        userId: m['user_id'],
        customerId: m['customer_id'],
        tableId: m['table_id'],
        subtotal: (m['subtotal'] as num).toDouble(),
        discountAmount: (m['discount_amount'] as num?)?.toDouble() ?? 0,
        discountType: m['discount_type'],
        discountValue: (m['discount_value'] as num?)?.toDouble() ?? 0,
        taxPercent: (m['tax_percent'] as num?)?.toDouble() ?? 0,
        taxAmount: (m['tax_amount'] as num?)?.toDouble() ?? 0,
        total: (m['total'] as num).toDouble(),
        totalPaid: (m['total_paid'] as num?)?.toDouble() ?? 0,
        change: (m['change_amount'] as num?)?.toDouble() ?? 0,
        status: m['status'] ?? 'completed',
        note: m['note'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'order_number': orderNumber,
        'shift_id': shiftId,
        'user_id': userId,
        'customer_id': customerId,
        'table_id': tableId,
        'subtotal': subtotal,
        'discount_amount': discountAmount,
        'discount_type': discountType,
        'discount_value': discountValue,
        'tax_percent': taxPercent,
        'tax_amount': taxAmount,
        'total': total,
        'total_paid': totalPaid,
        'change_amount': change,
        'status': status,
        'note': note,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, orderNumber];
}

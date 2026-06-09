import 'package:equatable/equatable.dart';

class StockMovement extends Equatable {
  final int? id;
  final int productId;
  final String? productName;
  final String type; // in | out | adjustment
  final int qty;
  final String? note;
  final String createdAt;

  const StockMovement({
    this.id,
    required this.productId,
    this.productName,
    required this.type,
    required this.qty,
    this.note,
    required this.createdAt,
  });

  factory StockMovement.fromMap(Map<String, dynamic> m) => StockMovement(
        id: m['id'],
        productId: m['product_id'],
        productName: m['product_name'],
        type: m['type'],
        qty: m['qty'],
        note: m['note'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'type': type,
        'qty': qty,
        'note': note,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, productId, type, qty];
}

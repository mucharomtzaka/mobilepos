import 'package:equatable/equatable.dart';
import 'product.dart';

class BundleItem extends Equatable {
  final int? id;
  final int bundleId;
  final int productId;
  final int qty;
  final Product? product;

  const BundleItem({
    this.id,
    required this.bundleId,
    required this.productId,
    this.qty = 1,
    this.product,
  });

  factory BundleItem.fromMap(Map<String, dynamic> m) => BundleItem(
        id: m['id'],
        bundleId: m['bundle_id'],
        productId: m['product_id'],
        qty: m['qty'] ?? 1,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'bundle_id': bundleId,
        'product_id': productId,
        'qty': qty,
      };

  BundleItem copyWith({int? id, int? bundleId, Product? product}) => BundleItem(
        id: id ?? this.id,
        bundleId: bundleId ?? this.bundleId,
        productId: productId,
        qty: qty,
        product: product ?? this.product,
      );

  @override
  List<Object?> get props => [id, bundleId, productId, qty];
}

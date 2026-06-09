import 'package:equatable/equatable.dart';
import 'product.dart';
import 'product_variant.dart';

class CartItem extends Equatable {
  final Product product;
  final ProductVariant? variant;
  final int qty;

  const CartItem({required this.product, this.variant, this.qty = 1});

  String get displayName => variant != null ? '${product.name} - ${variant!.name}' : product.name;

  double get effectivePrice => product.price + (variant?.priceAdjustment ?? 0);

  double get subtotal => effectivePrice * qty;

  String get cartKey => variant != null ? '${product.id}_${variant!.id}' : '${product.id}';

  CartItem copyWith({int? qty, ProductVariant? variant}) =>
      CartItem(product: product, variant: variant ?? this.variant, qty: qty ?? this.qty);

  @override
  List<Object?> get props => [product.id, variant?.id, qty];
}

enum DiscountType { percent, nominal }

class Discount extends Equatable {
  final DiscountType type;
  final double value;

  const Discount({required this.type, required this.value});

  double calculate(double subtotal) {
    if (type == DiscountType.percent) return subtotal * value / 100;
    return value > subtotal ? subtotal : value;
  }

  @override
  List<Object?> get props => [type, value];
}

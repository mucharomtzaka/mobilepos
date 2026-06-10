import 'package:equatable/equatable.dart';
import 'product.dart';
import 'product_variant.dart';

class CartItem extends Equatable {
  final Product product;
  final ProductVariant? variant;
  final int qty;
  final int? bundleId;
  final String? bundleName;
  final double? bundleAdjustedPrice;

  const CartItem({
    required this.product,
    this.variant,
    this.qty = 1,
    this.bundleId,
    this.bundleName,
    this.bundleAdjustedPrice,
  });

  String get displayName {
    if (bundleName != null) return '$bundleName: ${product.name}';
    return variant != null ? '${product.name} - ${variant!.name}' : product.name;
  }

  double get effectivePrice => bundleAdjustedPrice ?? (product.price + (variant?.priceAdjustment ?? 0));

  double get subtotal => effectivePrice * qty;

  String get cartKey {
    if (bundleId != null) return 'bundle_${bundleId}_${product.id}_${variant?.id}';
    return variant != null ? '${product.id}_${variant!.id}' : '${product.id}';
  }

  CartItem copyWith({int? qty, ProductVariant? variant, double? bundleAdjustedPrice}) =>
      CartItem(
        product: product,
        variant: variant ?? this.variant,
        qty: qty ?? this.qty,
        bundleId: bundleId,
        bundleName: bundleName,
        bundleAdjustedPrice: bundleAdjustedPrice ?? this.bundleAdjustedPrice,
      );

  @override
  List<Object?> get props => [product.id, variant?.id, qty, bundleId, bundleName];
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

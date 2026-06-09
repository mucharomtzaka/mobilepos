import 'package:equatable/equatable.dart';

class ProductVariant extends Equatable {
  final int? id;
  final int productId;
  final String name;
  final double priceAdjustment;
  final int stock;

  const ProductVariant({
    this.id,
    required this.productId,
    required this.name,
    this.priceAdjustment = 0,
    this.stock = 0,
  });

  factory ProductVariant.fromMap(Map<String, dynamic> m) => ProductVariant(
        id: m['id'],
        productId: m['product_id'],
        name: m['name'],
        priceAdjustment: (m['price_adjustment'] as num?)?.toDouble() ?? 0,
        stock: m['stock'] ?? 0,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'product_id': productId,
        'name': name,
        'price_adjustment': priceAdjustment,
        'stock': stock,
      };

  ProductVariant copyWith({int? id, int? productId, String? name, double? priceAdjustment, int? stock}) =>
      ProductVariant(
        id: id ?? this.id,
        productId: productId ?? this.productId,
        name: name ?? this.name,
        priceAdjustment: priceAdjustment ?? this.priceAdjustment,
        stock: stock ?? this.stock,
      );

  double get effectivePrice => priceAdjustment;

  @override
  List<Object?> get props => [id, productId, name, priceAdjustment, stock];
}

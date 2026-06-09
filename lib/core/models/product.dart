import 'package:equatable/equatable.dart';
import 'product_variant.dart';

class Product extends Equatable {
  final int? id;
  final int? categoryId;
  final String? categoryName;
  final String name;
  final String? barcode;
  final double price;
  final int stock;
  final String unit;
  final String? imagePath;
  final bool isActive;
  final String createdAt;
  final List<ProductVariant> variants;

  const Product({
    this.id,
    this.categoryId,
    this.categoryName,
    required this.name,
    this.barcode,
    required this.price,
    this.stock = 0,
    this.unit = 'pcs',
    this.imagePath,
    this.isActive = true,
    required this.createdAt,
    this.variants = const [],
  });

  factory Product.fromMap(Map<String, dynamic> m, {List<ProductVariant> variants = const []}) => Product(
        id: m['id'],
        categoryId: m['category_id'],
        categoryName: m['category_name'],
        name: m['name'],
        barcode: m['barcode'],
        price: (m['price'] as num).toDouble(),
        stock: m['stock'] ?? 0,
        unit: m['unit'] ?? 'pcs',
        imagePath: m['image_path'],
        isActive: m['is_active'] == 1,
        createdAt: m['created_at'],
        variants: variants,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'category_id': categoryId,
        'name': name,
        'barcode': barcode,
        'price': price,
        'stock': stock,
        'unit': unit,
        'image_path': imagePath,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Product copyWith({int? stock, List<ProductVariant>? variants}) => Product(
        id: id,
        categoryId: categoryId,
        categoryName: categoryName,
        name: name,
        barcode: barcode,
        price: price,
        stock: stock ?? this.stock,
        unit: unit,
        imagePath: imagePath,
        isActive: isActive,
        createdAt: createdAt,
        variants: variants ?? this.variants,
      );

  bool get hasVariants => variants.isNotEmpty;

  @override
  List<Object?> get props => [id, name, price, stock];
}

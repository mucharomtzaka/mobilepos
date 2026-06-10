import 'package:equatable/equatable.dart';

class Bundle extends Equatable {
  final int? id;
  final String name;
  final double price;
  final bool isActive;
  final String createdAt;

  const Bundle({
    this.id,
    required this.name,
    required this.price,
    this.isActive = true,
    required this.createdAt,
  });

  factory Bundle.fromMap(Map<String, dynamic> m) => Bundle(
        id: m['id'],
        name: m['name'],
        price: (m['price'] as num).toDouble(),
        isActive: m['is_active'] == 1,
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'price': price,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  Bundle copyWith({double? price, bool? isActive}) => Bundle(
        id: id,
        name: name,
        price: price ?? this.price,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt,
      );

  @override
  List<Object?> get props => [id, name, price];
}

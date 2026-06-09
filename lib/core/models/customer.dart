import 'package:equatable/equatable.dart';

class Customer extends Equatable {
  final int? id;
  final String name;
  final String? phone;
  final String createdAt;

  const Customer({
    this.id,
    required this.name,
    this.phone,
    required this.createdAt,
  });

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'],
        name: m['name'],
        phone: m['phone'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        if (phone != null) 'phone': phone,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, name, phone];
}

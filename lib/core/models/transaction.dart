import 'package:equatable/equatable.dart';

class Transaction extends Equatable {
  final int? id;
  final String type; // income | expense
  final String category;
  final double amount;
  final String? description;
  final String createdAt;

  const Transaction({
    this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.description,
    required this.createdAt,
  });

  factory Transaction.fromMap(Map<String, dynamic> m) => Transaction(
        id: m['id'],
        type: m['type'],
        category: m['category'],
        amount: (m['amount'] as num).toDouble(),
        description: m['description'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'type': type,
        'category': category,
        'amount': amount,
        'description': description,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, type, category, amount, createdAt];
}

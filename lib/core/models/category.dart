import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final int? id;
  final String name;
  final String createdAt;

  const Category({this.id, required this.name, required this.createdAt});

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'],
        name: m['name'],
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, name];
}

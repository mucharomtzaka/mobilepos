import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String name;
  final String username;
  final String password;
  final String role; // admin | kasir | merchant
  final bool isActive;
  final String createdAt;

  const User({
    this.id,
    required this.name,
    required this.username,
    required this.password,
    this.role = 'kasir',
    this.isActive = true,
    required this.createdAt,
  });

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'],
        name: m['name'],
        username: m['username'],
        password: m['password'],
        role: m['role'] ?? 'kasir',
        isActive: m['is_active'] == 1,
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'username': username,
        'password': password,
        'role': role,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  @override
  List<Object?> get props => [id, username];
}

import 'package:equatable/equatable.dart';

class RestoTable extends Equatable {
  final int? id;
  final String name;
  final int capacity;
  final String? note;
  final bool isActive;
  final String createdAt;

  const RestoTable({
    this.id,
    required this.name,
    this.capacity = 4,
    this.note,
    this.isActive = true,
    required this.createdAt,
  });

  factory RestoTable.fromMap(Map<String, dynamic> m) => RestoTable(
        id: m['id'],
        name: m['name'],
        capacity: (m['capacity'] as num?)?.toInt() ?? 4,
        note: m['note'],
        isActive: m['is_active'] == 1,
        createdAt: m['created_at'],
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'name': name,
        'capacity': capacity,
        'note': note,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  RestoTable copyWith({
    int? id,
    String? name,
    int? capacity,
    String? note,
    bool? isActive,
    String? createdAt,
  }) =>
      RestoTable(
        id: id ?? this.id,
        name: name ?? this.name,
        capacity: capacity ?? this.capacity,
        note: note ?? this.note,
        isActive: isActive ?? this.isActive,
        createdAt: createdAt ?? this.createdAt,
      );

  @override
  List<Object?> get props => [id, name];
}
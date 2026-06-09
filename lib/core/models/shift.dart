import 'package:equatable/equatable.dart';

class Shift extends Equatable {
  final int? id;
  final int userId;
  final String? userName;
  final String startTime;
  final String? endTime;
  final double openingCash;
  final double? closingCash;
  final String status; // open | closed

  const Shift({
    this.id,
    required this.userId,
    this.userName,
    required this.startTime,
    this.endTime,
    this.openingCash = 0,
    this.closingCash,
    this.status = 'open',
  });

  bool get isOpen => status == 'open';

  factory Shift.fromMap(Map<String, dynamic> m) => Shift(
        id: m['id'],
        userId: m['user_id'],
        userName: m['user_name'],
        startTime: m['start_time'],
        endTime: m['end_time'],
        openingCash: (m['opening_cash'] as num?)?.toDouble() ?? 0,
        closingCash: (m['closing_cash'] as num?)?.toDouble(),
        status: m['status'] ?? 'open',
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'start_time': startTime,
        'end_time': endTime,
        'opening_cash': openingCash,
        'closing_cash': closingCash,
        'status': status,
      };

  @override
  List<Object?> get props => [id, userId, status];
}

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/database/shift_dao.dart';
import '../../../core/models/shift.dart';

// Events
abstract class ShiftEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ShiftCheck extends ShiftEvent {
  final int userId;
  ShiftCheck(this.userId);
}

class ShiftOpenEvent extends ShiftEvent {
  final int userId;
  final double openingCash;
  ShiftOpenEvent(this.userId, this.openingCash);
}

class ShiftCloseEvent extends ShiftEvent {
  final int shiftId;
  final double closingCash;
  ShiftCloseEvent(this.shiftId, this.closingCash);
}

class ShiftLoadHistory extends ShiftEvent {
  final int? userId;
  ShiftLoadHistory([this.userId]);
}

// States
abstract class ShiftState extends Equatable {
  @override
  List<Object?> get props => [];
}

class ShiftInitial extends ShiftState {}
class ShiftLoading extends ShiftState {}

class ShiftOpen extends ShiftState {
  final Shift shift;
  ShiftOpen(this.shift);
  @override
  List<Object?> get props => [shift];
}

class ShiftClosed extends ShiftState {}

class ShiftHistory extends ShiftState {
  final List<Shift> shifts;
  ShiftHistory(this.shifts);
  @override
  List<Object?> get props => [shifts];
}

// BLoC
class ShiftBloc extends Bloc<ShiftEvent, ShiftState> {
  final ShiftDao _dao;

  ShiftBloc(this._dao) : super(ShiftInitial()) {
    on<ShiftCheck>(_onCheck);
    on<ShiftOpenEvent>(_onOpen);
    on<ShiftCloseEvent>(_onClose);
    on<ShiftLoadHistory>(_onHistory);
  }

  Future<void> _onCheck(ShiftCheck e, Emitter<ShiftState> emit) async {
    emit(ShiftLoading());
    final shift = await _dao.getOpenShift(e.userId);
    if (shift != null) {
      emit(ShiftOpen(shift));
    } else {
      emit(ShiftClosed());
    }
  }

  Future<void> _onOpen(ShiftOpenEvent e, Emitter<ShiftState> emit) async {
    final shift = Shift(
      userId: e.userId,
      startTime: DateTime.now().toIso8601String(),
      openingCash: e.openingCash,
    );
    await _dao.openShift(shift);
    final opened = await _dao.getOpenShift(e.userId);
    emit(ShiftOpen(opened!));
  }

  Future<void> _onClose(ShiftCloseEvent e, Emitter<ShiftState> emit) async {
    await _dao.closeShift(e.shiftId, e.closingCash);
    emit(ShiftClosed());
  }

  Future<void> _onHistory(ShiftLoadHistory e, Emitter<ShiftState> emit) async {
    final shifts = await _dao.getHistory(userId: e.userId);
    emit(ShiftHistory(shifts));
  }
}

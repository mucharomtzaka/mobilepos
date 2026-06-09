import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/settings_dao.dart';

abstract class ThemeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ThemeChanged extends ThemeEvent {
  final ThemeMode mode;
  ThemeChanged(this.mode);
  @override
  List<Object?> get props => [mode];
}

class ThemeLoadRequested extends ThemeEvent {}

class ThemeBloc extends Bloc<ThemeEvent, ThemeMode> {
  final SettingsDao _dao;

  ThemeBloc(this._dao) : super(ThemeMode.system) {
    on<ThemeChanged>(_onChanged);
    on<ThemeLoadRequested>(_onLoadRequested);
  }

  Future<void> _onChanged(ThemeChanged e, Emitter<ThemeMode> emit) async {
    emit(e.mode);
  }

  Future<void> _onLoadRequested(ThemeLoadRequested e, Emitter<ThemeMode> emit) async {
    final mode = await _dao.getThemeMode();
    emit(mode);
  }
}
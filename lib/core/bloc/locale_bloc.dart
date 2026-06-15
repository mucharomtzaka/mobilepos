import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../database/settings_dao.dart';

class LocaleBloc extends Bloc<Locale, Locale> {
  final SettingsDao _dao;
  static const _keyLanguage = 'language_code';

  LocaleBloc(this._dao) : super(const Locale('id', 'ID')) {
    on<Locale>(_onChanged);
  }

  Future<void> load() async {
    final code = await _dao.get(_keyLanguage);
    if (code != null) {
      emit(Locale(code, code == 'id' ? 'ID' : 'US'));
    }
  }

  Future<void> _onChanged(Locale locale, Emitter<Locale> emit) async {
    await _dao.set(_keyLanguage, locale.languageCode);
    emit(locale);
  }
}

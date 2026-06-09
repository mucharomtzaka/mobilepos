import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/user_dao.dart';
import '../../../core/models/user.dart';

// Events
abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;
  AuthLoginRequested(this.username, this.password);
  @override
  List<Object?> get props => [username, password];
}

class AuthRegisterRequested extends AuthEvent {
  final String name;
  final String username;
  final String password;
  final String role;
  AuthRegisterRequested({
    required this.name,
    required this.username,
    required this.password,
    this.role = 'kasir',
  });
  @override
  List<Object?> get props => [name, username, role];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthProfileUpdated extends AuthEvent {
  final User user;
  AuthProfileUpdated(this.user);
  @override
  List<Object?> get props => [user];
}

// States
abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class AuthAuthenticated extends AuthState {
  final User user;
  AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}
class AuthUnauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final UserDao _dao;
  static const _kUserId = 'logged_in_user_id';

  AuthBloc(this._dao) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
    on<AuthProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt(_kUserId);
    if (userId != null) {
      final user = await _dao.getById(userId);
      if (user != null) {
        emit(AuthAuthenticated(user));
        return;
      }
    }
    emit(AuthUnauthenticated());
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final user = await _dao.login(e.username, e.password);
    if (user != null) {
      await _saveSession(user.id!);
      emit(AuthAuthenticated(user));
    } else {
      emit(AuthError('Username atau password salah'));
    }
  }

  Future<void> _onRegister(
      AuthRegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final taken = await _dao.isUsernameTaken(e.username);
    if (taken) {
      emit(AuthError('Username sudah digunakan'));
      return;
    }
    await _dao.insert(User(
      name: e.name,
      username: e.username,
      password: e.password,
      role: e.role,
      isActive: true,
      createdAt: DateTime.now().toIso8601String(),
    ));
    final user = await _dao.login(e.username, e.password);
    await _saveSession(user!.id!);
    emit(AuthAuthenticated(user));
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserId);
    emit(AuthUnauthenticated());
  }

  void _onProfileUpdated(AuthProfileUpdated e, Emitter<AuthState> emit) {
    emit(AuthAuthenticated(e.user));
  }

  Future<void> _saveSession(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kUserId, userId);
  }
}

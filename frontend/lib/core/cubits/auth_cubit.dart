import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

// ─────────── States ───────────

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String token;
  final AuthUser user;
  AuthAuthenticated({required this.token, required this.user});

  @override
  List<Object?> get props => [token, user.id];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─────────── Cubit ───────────

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(AuthInitial());

  /// Called on app start — restores session from local storage.
  Future<void> checkAuth() async {
    emit(AuthLoading());
    try {
      final token = await _authService.getToken();
      final user = await _authService.getCachedUser();
      if (token != null && user != null) {
        emit(AuthAuthenticated(token: token, user: user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> register(String name, String email, String password) async {
    emit(AuthLoading());
    try {
      final result = await _authService.register(name, email, password);
      emit(AuthAuthenticated(token: result.token, user: result.user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final result = await _authService.login(email, password);
      emit(AuthAuthenticated(token: result.token, user: result.user));
    } catch (e) {
      emit(AuthError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    emit(AuthUnauthenticated());
  }
}

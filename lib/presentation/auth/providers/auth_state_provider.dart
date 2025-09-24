import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/domain/entities/user.dart';

class AuthStateNotifier extends StateNotifier<AuthState> {
  AuthStateNotifier() : super(AuthState.initial);

  User? _currentUser;
  String? _accessToken;
  String? _refreshToken; // TODO: JWT refresh token 기능 구현 시 사용

  User? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => state == AuthState.authenticated && _currentUser != null;

  void setLoading() {
    state = AuthState.loading;
  }

  void setAuthenticated(User user, String accessToken, [String? refreshToken]) {
    _currentUser = user;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    state = AuthState.authenticated;
  }

  void setUnauthenticated() {
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    state = AuthState.unauthenticated;
  }

  void setError() {
    state = AuthState.error;
  }

  void updateUser(User user) {
    if (state == AuthState.authenticated) {
      _currentUser = user;
    }
  }

  void logout() {
    setUnauthenticated();
  }
}

final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier();
});

final currentUserProvider = Provider<User?>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  return authNotifier.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final authNotifier = ref.watch(authStateProvider.notifier);
  return authNotifier.isAuthenticated;
});
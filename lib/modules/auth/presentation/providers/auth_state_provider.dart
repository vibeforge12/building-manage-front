import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/core/network/interceptors/auth_interceptor.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/core/constants/user_types.dart';

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

  Future<void> loginSuccess(Map<String, dynamic> userData, String accessToken) async {
    try {
      final user = User.fromJson(userData);
      _currentUser = user;
      _accessToken = accessToken;
      state = AuthState.authenticated;
    } catch (e) {
      setError();
      throw Exception('사용자 정보 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> checkAutoLogin(AuthRemoteDataSource authDataSource) async {
    setLoading();

    try {
      // 저장된 토큰 확인
      final accessToken = await AuthInterceptor.getCurrentToken();
      final refreshToken = await AuthInterceptor.getCurrentRefreshToken();

      if (accessToken == null || refreshToken == null) {
        setUnauthenticated();
        return;
      }

      // TODO: 토큰 유효성 검사 API가 있다면 여기서 호출
      // 지금은 refresh token을 사용해서 새 토큰 발급 시도
      try {
        final response = await authDataSource.refreshToken(refreshToken);
        final newTokenData = response['data'];

        if (newTokenData != null) {
          _accessToken = newTokenData['accessToken'];

          // 사용자 정보가 토큰에서 추출 가능하다면 설정
          if (newTokenData['user'] != null) {
            await loginSuccess(newTokenData['user'], _accessToken!);
          } else {
            // 임시로 토큰만 설정 (실제로는 사용자 정보를 별도 API로 가져와야 함)
            state = AuthState.authenticated;
          }
        } else {
          throw Exception('토큰 갱신 실패');
        }
      } catch (e) {
        // refresh token도 유효하지 않음
        await AuthInterceptor.clearToken();
        setUnauthenticated();
      }
    } catch (e) {
      setUnauthenticated();
    }
  }

  Future<void> logout() async {
    await AuthInterceptor.clearToken();
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
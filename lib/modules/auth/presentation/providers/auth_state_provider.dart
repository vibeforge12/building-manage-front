import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/core/network/interceptors/auth_interceptor.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';

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

  Future<void> loginSuccess(Map<String, dynamic> userData, String accessToken, [String? refreshToken]) async {
    try {
      final user = User.fromJson(userData);
      _currentUser = user;
      _accessToken = accessToken;
      _refreshToken = refreshToken;

      // ✅ 토큰을 SecureStorage에 저장 (앱 종료 후에도 유지)
      await AuthInterceptor.saveToken(accessToken);

      if (refreshToken != null && refreshToken.isNotEmpty) {
        await AuthInterceptor.saveRefreshToken(refreshToken);
      }

      state = AuthState.authenticated;
    } catch (e) {
      setError();
      throw Exception('사용자 정보 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> checkAutoLogin(AuthRemoteDataSource authDataSource) async {
    // 이미 로그인된 상태면 체크하지 않음
    if (state == AuthState.authenticated && _currentUser != null) {
      return;
    }

    try {
      // 저장된 토큰 확인 (iOS Keychain 접근 시 예외 발생 가능)
      String? accessToken;
      String? refreshToken;

      try {
        accessToken = await AuthInterceptor.getCurrentToken();
        refreshToken = await AuthInterceptor.getCurrentRefreshToken();
      } catch (e) {
        // iOS Keychain 접근 실패 시 (디바이스 재시작 직후 등)
        setUnauthenticated();
        return;
      }

      // 토큰이 없으면 API 호출 없이 바로 unauthenticated 상태로 전환
      if (accessToken == null || refreshToken == null) {
        setUnauthenticated();
        return;
      }

      // 토큰이 있을 때만 loading 상태로 전환 후 refresh 시도
      setLoading();

      // non-nullable로 변환 (위에서 null 체크 완료)
      final validRefreshToken = refreshToken;

      // Refresh 시도: 실패 시 1회 재시도 후 포기
      Future<Map<String, dynamic>> _attemptRefresh() async {
        return await authDataSource.refreshToken(validRefreshToken);
      }

      Map<String, dynamic>? response;
      try {
        response = await _attemptRefresh();
      } catch (e) {
        // 1차 실패: 1회 재시도
        try {
          response = await _attemptRefresh();
        } catch (e2) {
          response = null;
        }
      }

      if (response != null) {
        try {
          final newTokenData = response['data'] ?? response;
          final newAccess = newTokenData['accessToken'];
          final newRefresh = newTokenData['refreshToken'];

          if (newAccess is String && newAccess.isNotEmpty) {
            _accessToken = newAccess;
            await AuthInterceptor.saveToken(newAccess);
          }

          if (newRefresh is String && newRefresh.isNotEmpty) {
            _refreshToken = newRefresh;
            await AuthInterceptor.saveRefreshToken(newRefresh);
          }

          // 사용자 정보가 포함된 경우 반영
          final userData = newTokenData['user'];
          if (userData != null) {
            await loginSuccess(userData, _accessToken ?? '', _refreshToken);
          } else {
            // 사용자 정보가 없으면 자동 로그인 불가 (정상적인 인증 아님)
            await AuthInterceptor.clearToken();
            setUnauthenticated();
          }
        } catch (e) {
          await AuthInterceptor.clearToken();
          setUnauthenticated();
        }
      } else {
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
  // authStateProvider의 상태를 감시하여 상태 변경 시 자동으로 재계산
  ref.watch(authStateProvider);
  final authNotifier = ref.read(authStateProvider.notifier);
  return authNotifier.currentUser;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  // authStateProvider의 상태를 감시하여 상태 변경 시 자동으로 재계산
  ref.watch(authStateProvider);
  final authNotifier = ref.read(authStateProvider.notifier);
  return authNotifier.isAuthenticated;
});

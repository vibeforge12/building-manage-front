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
    // 이미 로그인된 상태면 체크하지 않음
    if (state == AuthState.authenticated && _currentUser != null) {
      return;
    }

    setLoading();

    try {
      // 저장된 토큰 확인
      final accessToken = await AuthInterceptor.getCurrentToken();
      final refreshToken = await AuthInterceptor.getCurrentRefreshToken();

      if (accessToken == null || refreshToken == null) {
        setUnauthenticated();
        return;
      }

      // Refresh 시도: 실패 시 1회 재시도 후 포기
      Future<Map<String, dynamic>> _attemptRefresh() async {
        return await authDataSource.refreshToken(refreshToken);
      }

      Map<String, dynamic>? response;
      try {
        response = await _attemptRefresh();
      } catch (e) {
        // 1차 실패: 로깅 후 1회 재시도
        // ignore: avoid_print
        print('Token refresh failed (attempt 1): $e');
        try {
          response = await _attemptRefresh();
        } catch (e2) {
          // ignore: avoid_print
          print('Token refresh failed (attempt 2): $e2');
          response = null;
        }
      }

      if (response != null) {
        final newTokenData = response['data'] ?? response;
        final newAccess = newTokenData['accessToken'];
        final newRefresh = newTokenData['refreshToken'];

        if (newAccess is String && newAccess.isNotEmpty) {
          _accessToken = newAccess;
          // 저장소에도 저장해두면 이후 요청 헤더 반영에 안전
          await AuthInterceptor.saveToken(newAccess);
        }

        if (newRefresh is String && newRefresh.isNotEmpty) {
          // refresh 토큰이 갱신되는 백엔드라면 저장
          // SharedPreferences 저장은 AuthInterceptor.onResponse 경유가 아니므로 여기서는 생략하거나
          // 전용 저장 메서드를 별도로 둘 수 있습니다. 간단화를 위해 생략.
        }

        // 사용자 정보가 포함된 경우 반영
        final userData = newTokenData['user'];
        if (userData != null) {
          await loginSuccess(userData, _accessToken ?? '');
        } else {
          // 사용자 정보가 없더라도 토큰만으로 인증 상태 유지
          state = AuthState.authenticated;
        }
      } else {
        // 두 번 모두 실패: 토큰 제거 후 미인증 처리
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

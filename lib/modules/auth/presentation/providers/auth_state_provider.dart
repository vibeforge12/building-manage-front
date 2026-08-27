import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/constants/auth_states.dart';
import 'package:building_manage_front/domain/entities/user.dart';
import 'package:building_manage_front/core/network/interceptors/auth_interceptor.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
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

  /// 서버에 닿지 못한 상태로 전환한다.
  ///
  /// [setUnauthenticated] 와 달리 **저장된 토큰을 지우지 않는다.** 로그아웃이 아니라
  /// "확인하지 못했다"는 뜻이므로, 연결이 회복되면 재시도만으로 복구되어야 한다.
  void setNetworkUnavailable() {
    state = AuthState.networkUnavailable;
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

      // 실패 사유를 반드시 보존한다.
      // 예전에는 여기서 예외를 버리고 response=null 로만 넘겨, 아래에서
      // "만료(401)"와 "서버에 못 닿음"을 구분하지 못한 채 토큰을 지웠다.
      // 그 결과 지하철·비행기모드·서버 재시작 구간에 앱을 켜면 로그아웃됐다.
      Map<String, dynamic>? response;
      Object? failure;
      try {
        response = await _attemptRefresh();
      } catch (e) {
        // 1차 실패: 잠깐 쉬었다가 1회 재시도.
        // 지연 없이 즉시 재시도하면 연결 거부 시 두 번 다 즉시 실패해
        // 순간적인 단절을 넘기지 못한다.
        await Future.delayed(const Duration(milliseconds: 800));
        try {
          response = await _attemptRefresh();
        } catch (e2) {
          failure = e2;
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
        // 토큰을 지울지 여부는 "실패했으니까"가 아니라 **인증이 거부됐을 때만** 판단한다.
        // AuthInterceptor.onError 도 statusCode != 401 이면 토큰을 건드리지 않는다.
        // 두 경로의 규칙이 어긋나면 한쪽에서만 로그아웃되는 현상이 생긴다.
        final apiFailure = ApiException.from(failure);

        if (apiFailure.isAuthError) {
          // refresh 토큰이 만료·무효 → 실제 로그아웃. 재로그인 외에 방법이 없다.
          await AuthInterceptor.clearToken();
          setUnauthenticated();
        } else {
          // 연결 실패·타임아웃·5xx 등 → 아직 모르는 것이지 로그아웃이 아니다.
          // 토큰을 남겨두고, 연결이 회복되면 재시도로 복구되게 한다.
          setNetworkUnavailable();
        }
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

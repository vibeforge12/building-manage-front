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

  Future<void> loginSuccess(Map<String, dynamic> userData, String accessToken) async {
    try {
      print('🔑 LOGIN SUCCESS - userData: $userData');
      final user = User.fromJson(userData);
      _currentUser = user;
      _accessToken = accessToken;
      state = AuthState.authenticated;
      print('✅ USER SET - userType: ${user.userType}, name: ${user.name}, id: ${user.id}');
    } catch (e) {
      print('❌ LOGIN ERROR: $e');
      setError();
      throw Exception('사용자 정보 처리 중 오류가 발생했습니다.');
    }
  }

  Future<void> checkAutoLogin(AuthRemoteDataSource authDataSource) async {
    // 이미 로그인된 상태면 체크하지 않음
    if (state == AuthState.authenticated && _currentUser != null) {
      print('✅ 이미 로그인된 상태 - 자동 로그인 스킵');
      return;
    }

    setLoading();

    try {
      print('🔄 저장된 토큰 확인 중...');
      // 저장된 토큰 확인
      final accessToken = await AuthInterceptor.getCurrentToken();
      final refreshToken = await AuthInterceptor.getCurrentRefreshToken();

      print('📋 Access Token: ${accessToken?.substring(0, 20) ?? 'null'}...');
      print('📋 Refresh Token: ${refreshToken?.substring(0, 20) ?? 'null'}...');

      if (accessToken == null || refreshToken == null) {
        print('⚠️ 저장된 토큰이 없음 - 로그인 화면으로 이동');
        setUnauthenticated();
        return;
      }

      // Refresh 시도: 실패 시 1회 재시도 후 포기
      Future<Map<String, dynamic>> _attemptRefresh() async {
        print('🔄 토큰 갱신 시도 중...');
        return await authDataSource.refreshToken(refreshToken);
      }

      Map<String, dynamic>? response;
      try {
        response = await _attemptRefresh();
        print('✅ 토큰 갱신 성공');
      } catch (e) {
        // 1차 실패: 로깅 후 1회 재시도
        print('⚠️ 토큰 갱신 실패 (1차 시도): $e');
        try {
          response = await _attemptRefresh();
          print('✅ 토큰 갱신 성공 (2차 시도)');
        } catch (e2) {
          print('❌ 토큰 갱신 실패 (2차 시도): $e2');
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
            print('✅ 새 Access Token 저장됨');
          }

          if (newRefresh is String && newRefresh.isNotEmpty) {
            print('✅ 새 Refresh Token 받음');
          }

          // 사용자 정보가 포함된 경우 반영
          final userData = newTokenData['user'];
          if (userData != null) {
            print('🔄 사용자 정보 로드 중...');
            await loginSuccess(userData, _accessToken ?? '');
            print('✅ 자동 로그인 완료');
          } else {
            print('⚠️ 사용자 정보 없음 - 토큰만으로 인증 상태 유지');
            state = AuthState.authenticated;
          }
        } catch (e) {
          print('❌ 응답 처리 중 오류: $e');
          await AuthInterceptor.clearToken();
          setUnauthenticated();
        }
      } else {
        print('❌ 토큰 갱신 실패 - 로그인 화면으로 이동');
        await AuthInterceptor.clearToken();
        setUnauthenticated();
      }
    } catch (e) {
      print('❌ 자동 로그인 중 예상치 못한 오류: $e');
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

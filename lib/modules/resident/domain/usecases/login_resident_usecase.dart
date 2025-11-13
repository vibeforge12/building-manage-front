import 'package:building_manage_front/modules/resident/domain/repositories/resident_auth_repository.dart';

/// 입주민 로그인 UseCase
///
/// 비즈니스 로직:
/// 1. 사용자명/비밀번호 유효성 검증
/// 2. Repository를 통한 로그인 수행
/// 3. 결과 반환
class LoginResidentUseCase {
  final ResidentAuthRepository _repository;

  LoginResidentUseCase(this._repository);

  /// 로그인 실행
  ///
  /// [username] 사용자 ID
  /// [password] 비밀번호
  ///
  /// Returns: User 데이터와 Access Token
  /// Throws: Exception if validation or login fails
  Future<Map<String, dynamic>> execute({
    required String username,
    required String password,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (username.trim().isEmpty) {
      throw Exception('아이디를 입력해 주세요.');
    }

    if (password.isEmpty) {
      throw Exception('비밀번호를 입력해 주세요.');
    }

    if (password.length < 4) {
      throw Exception('비밀번호는 최소 4자 이상이어야 합니다.');
    }

    // Repository를 통한 로그인
    try {
      final result = await _repository.login(
        username: username.trim(),
        password: password,
      );

      return result;
    } catch (e) {
      // 에러 메시지를 사용자 친화적으로 변환
      if (e.toString().contains('401')) {
        throw Exception('아이디 또는 비밀번호가 일치하지 않습니다.');
      }
      rethrow;
    }
  }
}

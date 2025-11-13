import 'package:building_manage_front/modules/resident/domain/repositories/resident_auth_repository.dart';

/// 입주민 회원가입 UseCase
///
/// 비즈니스 로직:
/// 1. 입력 데이터 유효성 검증
/// 2. Repository를 통한 회원가입 수행
/// 3. 결과 반환
class RegisterResidentUseCase {
  final ResidentAuthRepository _repository;

  RegisterResidentUseCase(this._repository);

  /// 회원가입 실행
  ///
  /// Returns: User 데이터와 Access Token
  /// Throws: Exception if validation or registration fails
  Future<Map<String, dynamic>> execute({
    required String buildingId,
    required String dong,
    required String ho,
    required String name,
    required String phoneNumber,
    required String username,
    required String password,
  }) async {
    // 비즈니스 규칙: 유효성 검증
    if (buildingId.trim().isEmpty) {
      throw Exception('건물을 선택해 주세요.');
    }

    if (dong.trim().isEmpty) {
      throw Exception('동을 입력해 주세요.');
    }

    if (ho.trim().isEmpty) {
      throw Exception('호수를 입력해 주세요.');
    }

    if (name.trim().isEmpty) {
      throw Exception('이름을 입력해 주세요.');
    }

    if (phoneNumber.trim().isEmpty) {
      throw Exception('전화번호를 입력해 주세요.');
    }

    // 전화번호 형식 검증 (간단한 버전)
    final phoneRegex = RegExp(r'^\d{10,11}$');
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    if (!phoneRegex.hasMatch(cleanedPhone)) {
      throw Exception('올바른 전화번호 형식이 아닙니다.');
    }

    if (username.trim().isEmpty) {
      throw Exception('아이디를 입력해 주세요.');
    }

    if (username.length < 4) {
      throw Exception('아이디는 최소 4자 이상이어야 합니다.');
    }

    if (password.isEmpty) {
      throw Exception('비밀번호를 입력해 주세요.');
    }

    if (password.length < 6) {
      throw Exception('비밀번호는 최소 6자 이상이어야 합니다.');
    }

    // Repository를 통한 회원가입
    try {
      final result = await _repository.register(
        buildingId: buildingId.trim(),
        dong: dong.trim(),
        ho: ho.trim(),
        name: name.trim(),
        phoneNumber: cleanedPhone,
        username: username.trim(),
        password: password,
      );

      return result;
    } catch (e) {
      // 에러 메시지를 사용자 친화적으로 변환
      if (e.toString().contains('409') || e.toString().contains('이미 존재')) {
        throw Exception('이미 등록된 아이디입니다.');
      }
      rethrow;
    }
  }
}

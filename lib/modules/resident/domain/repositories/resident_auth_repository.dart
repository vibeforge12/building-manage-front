import 'package:building_manage_front/domain/entities/user.dart';

/// 입주민 인증 Repository 인터페이스
///
/// Clean Architecture의 Dependency Inversion Principle을 따릅니다.
/// Domain Layer는 구현체를 알지 못하고 인터페이스만 의존합니다.
abstract class ResidentAuthRepository {
  /// 입주민 로그인
  ///
  /// [username] 사용자 ID
  /// [password] 비밀번호
  ///
  /// Returns: User 엔티티와 Access Token
  /// Throws: Exception if login fails
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  });

  /// 입주민 회원가입
  ///
  /// [buildingId] 건물 ID
  /// [dong] 동
  /// [ho] 호수
  /// [name] 이름
  /// [phoneNumber] 전화번호
  /// [username] 사용자 ID
  /// [password] 비밀번호
  ///
  /// Returns: User 엔티티와 Access Token
  /// Throws: Exception if registration fails
  Future<Map<String, dynamic>> register({
    required String buildingId,
    required String dong,
    required String ho,
    required String name,
    required String phoneNumber,
    required String username,
    required String password,
  });
}

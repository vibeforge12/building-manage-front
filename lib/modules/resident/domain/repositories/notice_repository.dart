import 'package:building_manage_front/modules/resident/domain/entities/notice.dart';

/// 공지사항 Repository 인터페이스
abstract class NoticeRepository {
  /// 공지사항 목록 조회
  ///
  /// Returns: Notice 리스트
  /// Throws: Exception if fetch fails
  Future<List<Notice>> getNotices();

  /// 이벤트 목록 조회
  ///
  /// Returns: 이벤트 타입 Notice 리스트
  /// Throws: Exception if fetch fails
  Future<List<Notice>> getEvents();

  /// 공지사항 상세 조회
  ///
  /// [id] 공지사항 ID
  ///
  /// Returns: Notice 엔티티
  /// Throws: Exception if not found
  Future<Notice> getNoticeById(String id);
}

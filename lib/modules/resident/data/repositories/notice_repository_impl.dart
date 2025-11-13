import 'package:building_manage_front/modules/resident/domain/repositories/notice_repository.dart';
import 'package:building_manage_front/modules/resident/domain/entities/notice.dart';
import 'package:building_manage_front/modules/resident/data/datasources/notice_remote_datasource.dart';

/// NoticeRepository 구현체
class NoticeRepositoryImpl implements NoticeRepository {
  final NoticeRemoteDataSource _dataSource;

  NoticeRepositoryImpl(this._dataSource);

  @override
  Future<List<Notice>> getNotices() async {
    try {
      final result = await _dataSource.getNotices();
      final notices = result['data'] as List<dynamic>? ?? [];

      return notices
          .map((json) => Notice.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<Notice>> getEvents() async {
    try {
      final result = await _dataSource.getEvents();
      final events = result['data'] as List<dynamic>? ?? [];

      return events
          .map((json) => Notice.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Notice> getNoticeById(String id) async {
    try {
      final result = await _dataSource.getNoticeById(id);
      return Notice.fromJson(result['data'] ?? result);
    } catch (e) {
      rethrow;
    }
  }
}

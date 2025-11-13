import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';
import 'package:building_manage_front/modules/manager/domain/repositories/attendance_repository.dart';
import 'package:building_manage_front/modules/manager/data/datasources/attendance_remote_datasource.dart';

/// 출퇴근 Repository 구현
///
/// DataSource를 통해 API 호출 후 Entity로 변환
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource _dataSource;

  AttendanceRepositoryImpl(this._dataSource);

  @override
  Future<Map<String, dynamic>> checkIn() async {
    try {
      final result = await _dataSource.checkIn();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> checkOut() async {
    try {
      final result = await _dataSource.checkOut();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<MonthlyAttendanceResponse> getMonthlyAttendance({
    required int year,
    required int month,
  }) async {
    try {
      final result = await _dataSource.getMonthlyAttendance(
        year: year,
        month: month,
      );
      return result;
    } catch (e) {
      rethrow;
    }
  }
}

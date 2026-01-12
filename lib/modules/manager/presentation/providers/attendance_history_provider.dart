import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/get_monthly_attendance_usecase.dart';
import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/manager/presentation/providers/manager_providers.dart';

/// 출퇴근 기록 조회 상태
class AttendanceHistoryState {
  final bool isLoading;
  final String? error;
  final int year;
  final int month;
  final List<AttendanceRecord> records;

  AttendanceHistoryState({
    this.isLoading = false,
    this.error,
    required this.year,
    required this.month,
    this.records = const [],
  });

  AttendanceHistoryState copyWith({
    bool? isLoading,
    String? error,
    int? year,
    int? month,
    List<AttendanceRecord>? records,
  }) {
    return AttendanceHistoryState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      year: year ?? this.year,
      month: month ?? this.month,
      records: records ?? this.records,
    );
  }

  /// 특정 날짜에 출근 기록이 있는지 확인
  bool hasCheckInOnDate(int day) {
    return records.any((record) =>
        record.type == AttendanceRecordType.checkIn &&
        record.createdAt.day == day);
  }

  /// 특정 날짜에 퇴근 기록이 있는지 확인
  bool hasCheckOutOnDate(int day) {
    return records.any((record) =>
        record.type == AttendanceRecordType.checkOut &&
        record.createdAt.day == day);
  }

  /// 특정 날짜의 출근 시간 가져오기
  String? getCheckInTime(int day) {
    try {
      final record = records.firstWhere(
        (record) =>
            record.type == AttendanceRecordType.checkIn &&
            record.createdAt.day == day,
      );
      final hour = record.createdAt.hour.toString().padLeft(2, '0');
      final minute = record.createdAt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return null;
    }
  }

  /// 특정 날짜의 퇴근 시간 가져오기
  String? getCheckOutTime(int day) {
    try {
      final record = records.firstWhere(
        (record) =>
            record.type == AttendanceRecordType.checkOut &&
            record.createdAt.day == day,
      );
      final hour = record.createdAt.hour.toString().padLeft(2, '0');
      final minute = record.createdAt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } catch (e) {
      return null;
    }
  }
}

/// 출퇴근 기록 조회 Notifier
class AttendanceHistoryNotifier extends StateNotifier<AttendanceHistoryState> {
  final GetMonthlyAttendanceUseCase _getMonthlyAttendanceUseCase;

  AttendanceHistoryNotifier(this._getMonthlyAttendanceUseCase)
      : super(AttendanceHistoryState(
          year: DateTime.now().year,
          month: DateTime.now().month,
        ));

  /// 월별 출퇴근 기록 조회
  Future<void> fetchMonthlyAttendance() async {
    state = state.copyWith(isLoading: true, error: null);

    try {

      final response = await _getMonthlyAttendanceUseCase.execute(
        year: state.year,
        month: state.month,
      );

      state = state.copyWith(
        isLoading: false,
        records: response.records,
      );
    } on ApiException catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: e.userFriendlyMessage,
      );
    } catch (e) {

      state = state.copyWith(
        isLoading: false,
        error: '출퇴근 기록 조회 중 오류가 발생했습니다.',
      );
    }
  }

  /// 이전 달로 이동
  void previousMonth() {
    if (state.month == 1) {
      state = state.copyWith(year: state.year - 1, month: 12);
    } else {
      state = state.copyWith(month: state.month - 1);
    }
    fetchMonthlyAttendance();
  }

  /// 다음 달로 이동
  void nextMonth() {
    if (state.month == 12) {
      state = state.copyWith(year: state.year + 1, month: 1);
    } else {
      state = state.copyWith(month: state.month + 1);
    }
    fetchMonthlyAttendance();
  }

  /// 특정 년월로 이동
  void setYearMonth(int year, int month) {
    state = state.copyWith(year: year, month: month);
    fetchMonthlyAttendance();
  }
}

/// 출퇴근 기록 조회 Provider
final attendanceHistoryProvider =
    StateNotifierProvider<AttendanceHistoryNotifier, AttendanceHistoryState>((ref) {
  final useCase = ref.watch(getMonthlyAttendanceUseCaseProvider);
  return AttendanceHistoryNotifier(useCase);
});

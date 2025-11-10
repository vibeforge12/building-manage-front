import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/manager/data/datasources/attendance_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

/// 출근/퇴근 상태
enum AttendanceStatus {
  notCheckedIn,  // 출근 전
  checkedIn,     // 출근 완료
  checkedOut,    // 퇴근 완료
  loading,       // 처리 중
}

/// 출근/퇴근 상태 관리
class AttendanceState {
  final AttendanceStatus status;
  final String? error;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  AttendanceState({
    this.status = AttendanceStatus.notCheckedIn,
    this.error,
    this.checkInTime,
    this.checkOutTime,
  });

  bool get isCheckedIn => status == AttendanceStatus.checkedIn;
  bool get isCheckedOut => status == AttendanceStatus.checkedOut;
  bool get isLoading => status == AttendanceStatus.loading;

  AttendanceState copyWith({
    AttendanceStatus? status,
    String? error,
    bool clearError = false,
    DateTime? checkInTime,
    DateTime? checkOutTime,
  }) {
    return AttendanceState(
      status: status ?? this.status,
      error: clearError ? null : (error ?? this.error),
      checkInTime: checkInTime ?? this.checkInTime,
      checkOutTime: checkOutTime ?? this.checkOutTime,
    );
  }
}

/// 출근 상태 관리 Notifier
class AttendanceNotifier extends StateNotifier<AttendanceState> {
  final AttendanceRemoteDataSource _dataSource;

  AttendanceNotifier(this._dataSource) : super(AttendanceState());

  /// 출근 처리
  Future<bool> checkIn() async {
    // 이미 출근한 경우
    if (state.isCheckedIn) {
      state = state.copyWith(error: '이미 출근하셨습니다.');
      return false;
    }

    // 이미 퇴근한 경우
    if (state.isCheckedOut) {
      state = state.copyWith(error: '이미 퇴근하였습니다.');
      return false;
    }

    state = state.copyWith(
      status: AttendanceStatus.loading,
      clearError: true,
    );

    try {
      print('🏢 출근 처리 시작 (Provider)');

      final response = await _dataSource.checkIn();

      print('✅ 출근 처리 성공 (Provider)');

      state = state.copyWith(
        status: AttendanceStatus.checkedIn,
        checkInTime: DateTime.now(),
        clearError: true,
      );

      return true;
    } on ApiException catch (e) {
      print('❌ 출근 처리 실패 (Provider): ${e.userFriendlyMessage}');
      print('❌ 에러 메시지: ${e.message}');

      // 서버에서 이미 출근 처리되었다고 응답한 경우, 클라이언트 상태도 출근으로 변경
      if (e.message?.contains('이미 출근') == true) {
        print('🔄 서버 상태와 동기화: 출근 상태로 변경');
        state = state.copyWith(
          status: AttendanceStatus.checkedIn,
          checkInTime: DateTime.now(),
          error: e.userFriendlyMessage,
        );
      } else {
        state = state.copyWith(
          status: AttendanceStatus.notCheckedIn,
          error: e.userFriendlyMessage,
        );
      }

      return false;
    } catch (e) {
      print('❌ 출근 처리 실패 (Provider): $e');

      state = state.copyWith(
        status: AttendanceStatus.notCheckedIn,
        error: '출근 처리 중 오류가 발생했습니다.',
      );

      return false;
    }
  }

  /// 퇴근 처리
  Future<bool> checkOut() async {
    // 출근하지 않은 경우
    if (!state.isCheckedIn) {
      state = state.copyWith(error: '출근하지 않았습니다.');
      return false;
    }

    // 이미 퇴근한 경우
    if (state.isCheckedOut) {
      state = state.copyWith(error: '이미 퇴근하였습니다.');
      return false;
    }

    state = state.copyWith(
      status: AttendanceStatus.loading,
      clearError: true,
    );

    try {
      print('🏃 퇴근 처리 시작 (Provider)');

      final response = await _dataSource.checkOut();

      print('✅ 퇴근 처리 성공 (Provider)');

      state = state.copyWith(
        status: AttendanceStatus.checkedOut,
        checkOutTime: DateTime.now(),
        clearError: true,
      );

      return true;
    } on ApiException catch (e) {
      print('❌ 퇴근 처리 실패 (Provider): ${e.userFriendlyMessage}');

      state = state.copyWith(
        status: AttendanceStatus.checkedIn,
        error: e.userFriendlyMessage,
      );

      return false;
    } catch (e) {
      print('❌ 퇴근 처리 실패 (Provider): $e');

      state = state.copyWith(
        status: AttendanceStatus.checkedIn,
        error: '퇴근 처리 중 오류가 발생했습니다.',
      );

      return false;
    }
  }

  /// 상태 초기화 (로그아웃 시 사용)
  void reset() {
    state = AttendanceState();
  }
}

/// 출근 상태 Provider
final attendanceProvider =
    StateNotifierProvider<AttendanceNotifier, AttendanceState>((ref) {
  final dataSource = ref.watch(attendanceRemoteDataSourceProvider);
  return AttendanceNotifier(dataSource);
});

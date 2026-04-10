import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/check_in_usecase.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/check_out_usecase.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/manager/data/datasources/attendance_remote_datasource.dart';
import 'package:building_manage_front/modules/manager/presentation/providers/manager_providers.dart';

/// 출근/퇴근 상태
enum AttendanceStatus {
  notCheckedIn,  // 출근 전
  checkedIn,     // 출근 완료
  checkedOut,    // 퇴근 완료
  loading,       // 처리 중
  initFailed,    // 초기화 실패 (네트워크 오류 등)
}

/// 출근/퇴근 상태 관리
class AttendanceState {
  final AttendanceStatus status;
  final String? error;
  final DateTime? checkInTime;
  final DateTime? checkOutTime;

  AttendanceState({
    this.status = AttendanceStatus.loading,
    this.error,
    this.checkInTime,
    this.checkOutTime,
  });

  bool get isCheckedIn => status == AttendanceStatus.checkedIn;
  bool get isCheckedOut => status == AttendanceStatus.checkedOut;
  bool get isLoading => status == AttendanceStatus.loading;
  bool get isInitFailed => status == AttendanceStatus.initFailed;

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
  final CheckInUseCase _checkInUseCase;
  final CheckOutUseCase _checkOutUseCase;
  final AttendanceRemoteDataSource _dataSource;

  AttendanceNotifier(
    this._checkInUseCase,
    this._checkOutUseCase,
    this._dataSource,
  ) : super(AttendanceState()) {
    Future.microtask(() => initialize());
  }

  /// 앱 시작 시 서버에서 오늘 출퇴근 상태를 가져와 메모리 상태와 동기화
  /// 최대 3회 재시도 (1초 간격)
  Future<void> initialize({int retryCount = 0}) async {
    state = state.copyWith(status: AttendanceStatus.loading, clearError: true);

    try {
      final todayStatus = await _dataSource.getTodayAttendanceStatus();

      final syncedStatus = switch (todayStatus) {
        'checkedOut' => AttendanceStatus.checkedOut,
        'checkedIn' => AttendanceStatus.checkedIn,
        _ => AttendanceStatus.notCheckedIn,
      };

      state = state.copyWith(status: syncedStatus, clearError: true);
    } catch (e) {
      if (retryCount < 2) {
        await Future.delayed(const Duration(seconds: 1));
        await initialize(retryCount: retryCount + 1);
      } else {
        // 3회 모두 실패 → 사용자에게 안내 후 버튼 비활성
        state = state.copyWith(
          status: AttendanceStatus.initFailed,
          error: '출퇴근 상태를 확인할 수 없습니다. 네트워크를 확인해 주세요.',
        );
      }
    }
  }

  /// 출근 처리 — 서버 권위(server-authoritative) 방식
  /// 로컬 상태 가드 없이 항상 서버에 요청하고, 성공/실패 후 서버에서 상태를 재동기화
  Future<bool> checkIn() async {
    state = state.copyWith(
      status: AttendanceStatus.loading,
      clearError: true,
    );

    try {
      await _checkInUseCase.execute();

      // 성공 후 서버에서 정확한 상태를 다시 가져옴
      await _syncFromServer();
      return true;
    } on ApiException catch (e) {
      // 서버 에러 후에도 서버에서 실제 상태를 가져와 동기화
      await _syncFromServer();
      state = state.copyWith(error: e.userFriendlyMessage);
      return false;
    } catch (e) {
      // 네트워크 에러 등 — 서버 동기화 시도, 실패 시 initFailed
      await _syncFromServer();
      state = state.copyWith(error: '출근 처리 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 퇴근 처리 — 서버 권위(server-authoritative) 방식
  Future<bool> checkOut() async {
    state = state.copyWith(
      status: AttendanceStatus.loading,
      clearError: true,
    );

    try {
      await _checkOutUseCase.execute();

      // 성공 후 서버에서 정확한 상태를 다시 가져옴
      await _syncFromServer();
      return true;
    } on ApiException catch (e) {
      // 서버 에러 후에도 서버에서 실제 상태를 가져와 동기화
      await _syncFromServer();
      state = state.copyWith(error: e.userFriendlyMessage);
      return false;
    } catch (e) {
      await _syncFromServer();
      state = state.copyWith(error: '퇴근 처리 중 오류가 발생했습니다.');
      return false;
    }
  }

  /// 서버에서 오늘 출퇴근 상태를 가져와 로컬 상태 동기화
  /// 동기화 실패 시 loading 상태에 멈추지 않도록 fallback 처리
  Future<void> _syncFromServer() async {
    try {
      final todayStatus = await _dataSource.getTodayAttendanceStatus();
      final syncedStatus = switch (todayStatus) {
        'checkedOut' => AttendanceStatus.checkedOut,
        'checkedIn' => AttendanceStatus.checkedIn,
        _ => AttendanceStatus.notCheckedIn,
      };
      state = state.copyWith(status: syncedStatus, clearError: true);
    } catch (_) {
      // 동기화 실패 시 — loading 상태에서 벗어나도록 fallback 설정
      if (state.isLoading) {
        state = state.copyWith(
          status: AttendanceStatus.notCheckedIn,
          error: '상태 동기화에 실패했습니다. 새로고침해 주세요.',
        );
      }
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
  final checkInUseCase = ref.watch(checkInUseCaseProvider);
  final checkOutUseCase = ref.watch(checkOutUseCaseProvider);
  final dataSource = ref.watch(attendanceRemoteDataSourceProvider);
  return AttendanceNotifier(checkInUseCase, checkOutUseCase, dataSource);
});

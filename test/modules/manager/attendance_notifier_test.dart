import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:building_manage_front/modules/manager/presentation/providers/attendance_provider.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/check_in_usecase.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/check_out_usecase.dart';
import 'package:building_manage_front/modules/manager/data/datasources/attendance_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

import 'attendance_notifier_test.mocks.dart';

@GenerateMocks([CheckInUseCase, CheckOutUseCase, AttendanceRemoteDataSource])
void main() {
  late MockCheckInUseCase mockCheckInUseCase;
  late MockCheckOutUseCase mockCheckOutUseCase;
  late MockAttendanceRemoteDataSource mockDataSource;

  setUp(() {
    mockCheckInUseCase = MockCheckInUseCase();
    mockCheckOutUseCase = MockCheckOutUseCase();
    mockDataSource = MockAttendanceRemoteDataSource();
  });

  /// initialize() 없이 순수 상태만 테스트하기 위한 헬퍼
  /// initialize()는 생성자에서 자동 호출되므로, 테스트별로 dataSource 동작을 먼저 stub해야 함
  AttendanceNotifier buildNotifier() {
    return AttendanceNotifier(mockCheckInUseCase, mockCheckOutUseCase, mockDataSource);
  }

  group('initialize()', () {
    test('오늘 출근 기록 없음 → notCheckedIn', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'notCheckedIn');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero); // microtask 실행 대기

      expect(notifier.state.status, AttendanceStatus.notCheckedIn);
      expect(notifier.state.isInitFailed, false);
    });

    test('오늘 출근 기록 있음 → checkedIn 복원', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state.status, AttendanceStatus.checkedIn);
    });

    test('오늘 출퇴근 모두 완료 → checkedOut 복원', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedOut');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state.status, AttendanceStatus.checkedOut);
    });

    test('네트워크 실패 1회 후 재시도 성공 → checkedIn', () async {
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('network error');
        return 'checkedIn';
      });

      final notifier = buildNotifier();
      await Future.delayed(const Duration(seconds: 2)); // 재시도 1초 대기

      expect(notifier.state.status, AttendanceStatus.checkedIn);
      expect(callCount, 2);
    });

    test('3회 모두 실패 → initFailed', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenThrow(Exception('network error'));

      final notifier = buildNotifier();
      await Future.delayed(const Duration(seconds: 4)); // 3회 재시도(3초) 대기

      expect(notifier.state.status, AttendanceStatus.initFailed);
      expect(notifier.state.isInitFailed, true);
      expect(notifier.state.error, isNotNull);
    });
  });

  group('checkIn()', () {
    test('출근 전 상태에서 출근 성공 → checkedIn', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'notCheckedIn');
      when(mockCheckInUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedIn);
    });

    test('이미 출근 상태에서 출근 시도 → false 반환, 상태 유지', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.checkedIn);
      verifyNever(mockCheckInUseCase.execute());
    });

    test('이미 퇴근 상태에서 출근 시도 → false 반환', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedOut');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      verifyNever(mockCheckInUseCase.execute());
    });

    test('출근 API 실패 → notCheckedIn 유지', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'notCheckedIn');
      when(mockCheckInUseCase.execute()).thenThrow(
        ApiException(message: '서버 오류', errorCode: 'SERVER_ERROR'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.notCheckedIn);
    });
  });

  group('checkOut()', () {
    test('출근 상태에서 퇴근 성공 → checkedOut', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');
      when(mockCheckOutUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedOut);
    });

    test('출근 안 한 상태에서 퇴근 시도 → false 반환 (핵심 버그 케이스)', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'notCheckedIn');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.notCheckedIn);
      verifyNever(mockCheckOutUseCase.execute());
    });

    test('이미 퇴근 상태에서 퇴근 시도 → false 반환', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedOut');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, false);
      verifyNever(mockCheckOutUseCase.execute());
    });

    test('퇴근 API 실패 → checkedIn 상태 유지', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');
      when(mockCheckOutUseCase.execute()).thenThrow(
        ApiException(message: '서버 오류', errorCode: 'SERVER_ERROR'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.checkedIn);
    });
  });

  group('앱 재시작 시뮬레이션', () {
    test('출근 후 앱 종료 → 재시작 시 checkedIn 복원 후 퇴근 가능', () async {
      // 앱 재시작: 서버에 출근 기록 있음
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');
      when(mockCheckOutUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      // 퇴근 버튼 클릭
      final result = await notifier.checkOut();

      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedOut);
    });
  });
}

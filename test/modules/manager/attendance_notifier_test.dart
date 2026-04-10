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

    test('초기 상태는 loading이어야 한다 (버튼 비활성화)', () {
      // getTodayAttendanceStatus를 호출하지 않아 초기 상태를 확인
      final state = AttendanceState();
      expect(state.status, AttendanceStatus.loading);
      expect(state.isLoading, true);
    });
  });

  group('checkIn() - 서버 권위(server-authoritative) 방식', () {
    test('출근 전 상태에서 출근 성공 → 서버 동기화 후 checkedIn', () async {
      // initialize() 용: notCheckedIn 반환
      // checkIn 후 _syncFromServer(): checkedIn 반환
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'notCheckedIn'; // initialize()
        return 'checkedIn'; // _syncFromServer() after checkIn
      });
      when(mockCheckInUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedIn);
      verify(mockCheckInUseCase.execute()).called(1);
    });

    test('이미 출근 상태에서도 서버에 요청함 (서버가 거절)', () async {
      // 서버 권위: 로컬 가드 없이 항상 서버에 요청
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');
      when(mockCheckInUseCase.execute()).thenThrow(
        const ApiException(message: '이미 출근하셨습니다.', errorCode: 'ALREADY_CHECKED_IN'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.checkedIn); // 서버 동기화로 유지
      verify(mockCheckInUseCase.execute()).called(1); // 서버에 요청함
    });

    test('이미 퇴근 상태에서도 서버에 요청함 (서버가 거절)', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedOut');
      when(mockCheckInUseCase.execute()).thenThrow(
        const ApiException(message: '이미 퇴근하셨습니다.', errorCode: 'ALREADY_CHECKED_OUT'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.checkedOut); // 서버 동기화로 유지
      verify(mockCheckInUseCase.execute()).called(1);
    });

    test('출근 API 실패 → 서버 동기화 후 상태 결정', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'notCheckedIn');
      when(mockCheckInUseCase.execute()).thenThrow(
        const ApiException(message: '서버 오류', errorCode: 'SERVER_ERROR'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.notCheckedIn);
      expect(notifier.state.error, isNotNull);
    });

    test('checkIn 성공 후 _syncFromServer 실패 → loading에서 탈출하여 notCheckedIn + 에러 메시지', () async {
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'notCheckedIn'; // initialize()
        throw Exception('network error'); // _syncFromServer() 실패
      });
      when(mockCheckInUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      // API 성공이므로 true 반환
      expect(result, true);
      // 핵심: loading 상태에 멈추지 않고 notCheckedIn으로 fallback
      expect(notifier.state.status, isNot(AttendanceStatus.loading));
      expect(notifier.state.status, AttendanceStatus.notCheckedIn);
      expect(notifier.state.error, contains('동기화'));
    });
  });

  group('checkOut() - 서버 권위(server-authoritative) 방식', () {
    test('출근 상태에서 퇴근 성공 → 서버 동기화 후 checkedOut', () async {
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'checkedIn'; // initialize()
        return 'checkedOut'; // _syncFromServer() after checkOut
      });
      when(mockCheckOutUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedOut);
      verify(mockCheckOutUseCase.execute()).called(1);
    });

    test('출근 안 한 상태에서도 서버에 요청함 (서버가 거절)', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'notCheckedIn');
      when(mockCheckOutUseCase.execute()).thenThrow(
        const ApiException(message: '출근 처리 후 퇴근이 가능합니다.', errorCode: 'NOT_CHECKED_IN'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.notCheckedIn);
      verify(mockCheckOutUseCase.execute()).called(1); // 서버에 요청함
    });

    test('이미 퇴근 상태에서도 서버에 요청함 (서버가 거절)', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedOut');
      when(mockCheckOutUseCase.execute()).thenThrow(
        const ApiException(message: '이미 퇴근하셨습니다.', errorCode: 'ALREADY_CHECKED_OUT'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.checkedOut);
      verify(mockCheckOutUseCase.execute()).called(1);
    });

    test('퇴근 API 실패 → 서버 동기화 후 checkedIn 상태 유지', () async {
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');
      when(mockCheckOutUseCase.execute()).thenThrow(
        const ApiException(message: '서버 오류', errorCode: 'SERVER_ERROR'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, false);
      expect(notifier.state.status, AttendanceStatus.checkedIn);
    });
  });

  group('[버그 리포트] 출퇴근 상태 꼬임 시나리오', () {
    test('버그#1: 출근 성공 후 상태가 미출근으로 변경되지 않아야 함', () async {
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'notCheckedIn'; // initialize()
        return 'checkedIn'; // _syncFromServer() after checkIn
      });
      when(mockCheckInUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);
      expect(notifier.state.status, AttendanceStatus.notCheckedIn);

      // 출근
      final result = await notifier.checkIn();
      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedIn);

      // 핵심: 출근 후 상태가 notCheckedIn으로 돌아가지 않음
      expect(notifier.state.status, isNot(AttendanceStatus.notCheckedIn));
    });

    test('버그#2: 미출근 상태에서 재출근 시 서버가 "이미 출근" → 상태 checkedIn으로 동기화', () async {
      // 시나리오: 출근했는데 UI가 미출근으로 표시 → 재출근 시도 → 서버 거절 → 서버 동기화
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'notCheckedIn'; // initialize() — stale 상태
        return 'checkedIn'; // _syncFromServer() — 서버의 실제 상태
      });
      when(mockCheckInUseCase.execute()).thenThrow(
        const ApiException(message: '이미 출근하셨습니다.', errorCode: 'ALREADY_CHECKED_IN'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      // 핵심: 서버 동기화로 정확한 상태 반영 (미출근이 아님)
      expect(notifier.state.status, AttendanceStatus.checkedIn);
      expect(notifier.state.error, contains('이미 출근'));
    });

    test('버그#3: 퇴근 후 상태가 미출근이 아닌 checkedOut으로 표시되어야 함', () async {
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'checkedIn'; // initialize()
        return 'checkedOut'; // _syncFromServer() after checkOut
      });
      when(mockCheckOutUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);
      expect(notifier.state.status, AttendanceStatus.checkedIn);

      // 퇴근
      final result = await notifier.checkOut();

      expect(result, true);
      // 핵심: 퇴근 후 미출근이 아닌 checkedOut으로 표시
      expect(notifier.state.status, AttendanceStatus.checkedOut);
      expect(notifier.state.status, isNot(AttendanceStatus.notCheckedIn));
    });

    test('버그#4: checkOut 성공 후 _syncFromServer 실패 → loading에 멈추지 않아야 함', () async {
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'checkedIn'; // initialize()
        throw Exception('network error'); // _syncFromServer() 실패
      });
      when(mockCheckOutUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkOut();

      expect(result, true);
      // 핵심: loading 상태에 멈추지 않음
      expect(notifier.state.status, isNot(AttendanceStatus.loading));
      expect(notifier.state.error, contains('동기화'));
    });
  });

  group('앱 재시작 시뮬레이션', () {
    test('출근 후 앱 종료 → 재시작 시 checkedIn 복원 후 퇴근 가능', () async {
      // 앱 재시작: 서버에 출근 기록 있음
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount <= 1) return 'checkedIn'; // initialize()
        return 'checkedOut'; // _syncFromServer() after checkOut
      });
      when(mockCheckOutUseCase.execute()).thenAnswer((_) async => {'success': true});

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      // 퇴근 버튼 클릭
      final result = await notifier.checkOut();

      expect(result, true);
      expect(notifier.state.status, AttendanceStatus.checkedOut);
    });
  });

  group('다중 기기 시나리오', () {
    test('기기A에서 출근 → 기기B initialize() → checkedIn 동기화', () async {
      // 기기B가 시작되면 서버에서 최신 상태를 가져옴
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async => 'checkedIn');

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      expect(notifier.state.status, AttendanceStatus.checkedIn);
    });

    test('기기A에서 출근 + 퇴근 → 기기B에서 출근 시도 → 서버가 거절 + 동기화', () async {
      // 기기B의 initialize()는 아직 notCheckedIn (이전 상태)
      // 하지만 출근 시도하면 서버가 이미 퇴근이라고 거절
      var callCount = 0;
      when(mockDataSource.getTodayAttendanceStatus()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) return 'notCheckedIn'; // initialize() (stale)
        return 'checkedOut'; // _syncFromServer() (fresh)
      });
      when(mockCheckInUseCase.execute()).thenThrow(
        const ApiException(message: '이미 퇴근하셨습니다.', errorCode: 'ALREADY_CHECKED_OUT'),
      );

      final notifier = buildNotifier();
      await Future.delayed(Duration.zero);

      final result = await notifier.checkIn();

      expect(result, false);
      // 핵심: 서버 동기화로 정확한 상태 반영
      expect(notifier.state.status, AttendanceStatus.checkedOut);
    });
  });
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

/// 담당자 계정 발급 상태
class StaffAccountIssuanceState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? createdStaff;
  final bool isSuccess;

  StaffAccountIssuanceState({
    this.isLoading = false,
    this.error,
    this.createdStaff,
    this.isSuccess = false,
  });

  StaffAccountIssuanceState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? createdStaff,
    bool? isSuccess,
  }) {
    return StaffAccountIssuanceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      createdStaff: createdStaff ?? this.createdStaff,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

/// 담당자 계정 발급 관리 Notifier
class StaffAccountIssuanceNotifier extends StateNotifier<StaffAccountIssuanceState> {
  final Ref _ref;

  StaffAccountIssuanceNotifier(this._ref) : super(StaffAccountIssuanceState());

  /// 담당자 계정 발급 (UseCase를 통한 비즈니스 로직 포함)
  Future<void> createStaffAccount({
    required String name,
    required String phoneNumber,
    required String departmentId,
    String? imageUrl,
  }) async {
    state = state.copyWith(isLoading: true, error: null, isSuccess: false);

    try {
      print('🚀 ========== 담당자 계정 발급 시작 ==========');
      print('📝 입력 정보:');
      print('   - 이름: $name');
      print('   - 전화번호: $phoneNumber');
      print('   - 부서 ID: $departmentId');
      print('   - 이미지 URL: ${imageUrl ?? "(없음)"}');

      // UseCase를 통한 담당자 계정 생성 (비즈니스 로직 포함)
      final createStaffUseCase = _ref.read(createStaffUseCaseProvider);
      final staff = await createStaffUseCase.execute(
        name: name,
        phoneNumber: phoneNumber,
        departmentId: departmentId,
        imageUrl: imageUrl,
      );

      print('✅ ========== 담당자 계정 발급 성공 ==========');
      print('📦 생성된 Staff:');
      print('   $staff');

      state = state.copyWith(
        isLoading: false,
        createdStaff: staff.toJson(),
        isSuccess: true,
      );
    } on ApiException catch (e) {
      print('❌ ========== API 에러 발생 ==========');
      print('   에러 메시지: ${e.userFriendlyMessage}');
      print('   에러 코드: ${e.errorCode}');
      print('   상태 코드: ${e.statusCode}');

      state = state.copyWith(
        isLoading: false,
        error: e.userFriendlyMessage,
        isSuccess: false,
      );
    } catch (e) {
      print('❌ ========== 일반 에러 발생 ==========');
      print('   에러: $e');

      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        isSuccess: false,
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = StaffAccountIssuanceState();
  }
}

/// 담당자 계정 발급 Provider
final staffAccountIssuanceProvider =
    StateNotifierProvider<StaffAccountIssuanceNotifier, StaffAccountIssuanceState>((ref) {
  return StaffAccountIssuanceNotifier(ref);
});

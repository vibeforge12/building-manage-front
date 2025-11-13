import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/data/datasources/resident_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/data/repositories/staff_repository_impl.dart';
import 'package:building_manage_front/modules/admin/data/repositories/resident_management_repository_impl.dart';
import 'package:building_manage_front/modules/admin/domain/repositories/staff_repository.dart';
import 'package:building_manage_front/modules/admin/domain/repositories/resident_management_repository.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/create_staff_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/get_staffs_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/get_staff_detail_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/update_staff_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/delete_staff_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/get_residents_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/verify_resident_usecase.dart';
import 'package:building_manage_front/modules/admin/domain/usecases/reject_resident_usecase.dart';

// ============================================================================
// DataSource Providers
// ============================================================================

/// Staff DataSource Provider (이미 정의된 것 재사용)
/// lib/modules/admin/data/datasources/staff_remote_datasource.dart에 정의됨

/// Resident DataSource Provider (이미 정의된 것 재사용)
/// lib/modules/admin/data/datasources/resident_remote_datasource.dart에 정의됨

// ============================================================================
// Repository Providers
// ============================================================================

/// Staff Repository Provider
final staffRepositoryProvider = Provider<StaffRepository>((ref) {
  final dataSource = ref.read(staffRemoteDataSourceProvider);
  return StaffRepositoryImpl(dataSource);
});

/// Resident Management Repository Provider
final residentManagementRepositoryProvider =
    Provider<ResidentManagementRepository>((ref) {
  final dataSource = ref.read(residentRemoteDataSourceProvider);
  return ResidentManagementRepositoryImpl(dataSource);
});

// ============================================================================
// UseCase Providers - Staff
// ============================================================================

/// 담당자 계정 발급 UseCase Provider
final createStaffUseCaseProvider = Provider<CreateStaffUseCase>((ref) {
  final repository = ref.read(staffRepositoryProvider);
  return CreateStaffUseCase(repository);
});

/// 담당자 목록 조회 UseCase Provider
final getStaffsUseCaseProvider = Provider<GetStaffsUseCase>((ref) {
  final repository = ref.read(staffRepositoryProvider);
  return GetStaffsUseCase(repository);
});

/// 담당자 상세 조회 UseCase Provider
final getStaffDetailUseCaseProvider = Provider<GetStaffDetailUseCase>((ref) {
  final repository = ref.read(staffRepositoryProvider);
  return GetStaffDetailUseCase(repository);
});

/// 담당자 정보 수정 UseCase Provider
final updateStaffUseCaseProvider = Provider<UpdateStaffUseCase>((ref) {
  final repository = ref.read(staffRepositoryProvider);
  return UpdateStaffUseCase(repository);
});

/// 담당자 삭제 UseCase Provider
final deleteStaffUseCaseProvider = Provider<DeleteStaffUseCase>((ref) {
  final repository = ref.read(staffRepositoryProvider);
  return DeleteStaffUseCase(repository);
});

// ============================================================================
// UseCase Providers - Resident Management
// ============================================================================

/// 입주민 목록 조회 UseCase Provider
final getResidentsUseCaseProvider = Provider<GetResidentsUseCase>((ref) {
  final repository = ref.read(residentManagementRepositoryProvider);
  return GetResidentsUseCase(repository);
});

/// 입주민 승인 UseCase Provider
final verifyResidentUseCaseProvider = Provider<VerifyResidentUseCase>((ref) {
  final repository = ref.read(residentManagementRepositoryProvider);
  return VerifyResidentUseCase(repository);
});

/// 입주민 거절 UseCase Provider
final rejectResidentUseCaseProvider = Provider<RejectResidentUseCase>((ref) {
  final repository = ref.read(residentManagementRepositoryProvider);
  return RejectResidentUseCase(repository);
});

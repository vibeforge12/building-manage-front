import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/manager/data/datasources/attendance_remote_datasource.dart';
import 'package:building_manage_front/modules/manager/data/datasources/staff_complaints_remote_datasource.dart';
import 'package:building_manage_front/modules/manager/data/repositories/attendance_repository_impl.dart';
import 'package:building_manage_front/modules/manager/data/repositories/complaint_resolve_repository_impl.dart';
import 'package:building_manage_front/modules/manager/domain/repositories/attendance_repository.dart';
import 'package:building_manage_front/modules/manager/domain/repositories/complaint_resolve_repository.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/check_in_usecase.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/check_out_usecase.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/get_monthly_attendance_usecase.dart';
import 'package:building_manage_front/modules/manager/domain/usecases/resolve_complaint_usecase.dart';

/// ===================================
/// Data Layer Providers
/// ===================================

/// AttendanceRemoteDataSource Provider
/// (이미 attendance_remote_datasource.dart에 정의되어 있음)

/// ===================================
/// Repository Providers
/// ===================================

/// AttendanceRepository Provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final dataSource = ref.watch(attendanceRemoteDataSourceProvider);
  return AttendanceRepositoryImpl(dataSource);
});

/// ComplaintResolveRepository Provider
final complaintResolveRepositoryProvider = Provider<ComplaintResolveRepository>((ref) {
  final dataSource = ref.watch(staffComplaintsRemoteDataSourceProvider);
  return ComplaintResolveRepositoryImpl(dataSource);
});

/// ===================================
/// UseCase Providers
/// ===================================

/// 출근 처리 UseCase Provider
final checkInUseCaseProvider = Provider<CheckInUseCase>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return CheckInUseCase(repository);
});

/// 퇴근 처리 UseCase Provider
final checkOutUseCaseProvider = Provider<CheckOutUseCase>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return CheckOutUseCase(repository);
});

/// 월별 출퇴근 기록 조회 UseCase Provider
final getMonthlyAttendanceUseCaseProvider = Provider<GetMonthlyAttendanceUseCase>((ref) {
  final repository = ref.watch(attendanceRepositoryProvider);
  return GetMonthlyAttendanceUseCase(repository);
});

/// 민원 처리 등록 UseCase Provider
final resolveComplaintUseCaseProvider = Provider<ResolveComplaintUseCase>((ref) {
  final repository = ref.watch(complaintResolveRepositoryProvider);
  return ResolveComplaintUseCase(repository);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/modules/resident/data/datasources/resident_auth_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/data/datasources/complaint_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/data/repositories/resident_auth_repository_impl.dart';
import 'package:building_manage_front/modules/resident/data/repositories/complaint_repository_impl.dart';
import 'package:building_manage_front/modules/resident/data/repositories/notice_repository_impl.dart';
import 'package:building_manage_front/modules/resident/data/repositories/department_repository_impl.dart';
import 'package:building_manage_front/modules/resident/domain/repositories/resident_auth_repository.dart';
import 'package:building_manage_front/modules/resident/domain/repositories/complaint_repository.dart';
import 'package:building_manage_front/modules/resident/domain/repositories/notice_repository.dart';
import 'package:building_manage_front/modules/resident/domain/repositories/department_repository.dart';
import 'package:building_manage_front/modules/resident/domain/usecases/login_resident_usecase.dart';
import 'package:building_manage_front/modules/resident/domain/usecases/register_resident_usecase.dart';
import 'package:building_manage_front/modules/resident/domain/usecases/create_complaint_usecase.dart';

// ============================================================================
// DataSources
// ============================================================================

final residentAuthRemoteDataSourceProvider = Provider<ResidentAuthRemoteDataSource>((ref) {
  return ResidentAuthRemoteDataSource(ApiClient());
});

final complaintRemoteDataSourceProvider = Provider<ComplaintRemoteDataSource>((ref) {
  return ComplaintRemoteDataSource(ApiClient());
});

final noticeRemoteDataSourceProvider = Provider<NoticeRemoteDataSource>((ref) {
  return NoticeRemoteDataSource(ApiClient());
});

final departmentRemoteDataSourceProvider = Provider<DepartmentRemoteDataSource>((ref) {
  return DepartmentRemoteDataSource(ApiClient());
});

// ============================================================================
// Repositories
// ============================================================================

final residentAuthRepositoryProvider = Provider<ResidentAuthRepository>((ref) {
  final dataSource = ref.read(residentAuthRemoteDataSourceProvider);
  return ResidentAuthRepositoryImpl(dataSource);
});

final complaintRepositoryProvider = Provider<ComplaintRepository>((ref) {
  final dataSource = ref.read(complaintRemoteDataSourceProvider);
  return ComplaintRepositoryImpl(dataSource);
});

final noticeRepositoryProvider = Provider<NoticeRepository>((ref) {
  final dataSource = ref.read(noticeRemoteDataSourceProvider);
  return NoticeRepositoryImpl(dataSource);
});

final departmentRepositoryProvider = Provider<DepartmentRepository>((ref) {
  final dataSource = ref.read(departmentRemoteDataSourceProvider);
  return DepartmentRepositoryImpl(dataSource);
});

// ============================================================================
// UseCases
// ============================================================================

final loginResidentUseCaseProvider = Provider<LoginResidentUseCase>((ref) {
  final repository = ref.read(residentAuthRepositoryProvider);
  return LoginResidentUseCase(repository);
});

final registerResidentUseCaseProvider = Provider<RegisterResidentUseCase>((ref) {
  final repository = ref.read(residentAuthRepositoryProvider);
  return RegisterResidentUseCase(repository);
});

final createComplaintUseCaseProvider = Provider<CreateComplaintUseCase>((ref) {
  final repository = ref.read(complaintRepositoryProvider);
  return CreateComplaintUseCase(repository);
});

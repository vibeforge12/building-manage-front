import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/building_remote_datasource.dart';
import 'package:building_manage_front/modules/headquarters/data/repositories/building_repository_impl.dart';
import 'package:building_manage_front/modules/headquarters/domain/repositories/building_repository.dart';
import 'package:building_manage_front/modules/headquarters/domain/usecases/create_building_usecase.dart';
import 'package:building_manage_front/modules/headquarters/domain/usecases/get_buildings_usecase.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';

/// ===================================
/// Data Layer Providers
/// ===================================

/// BuildingRemoteDataSource Provider
final buildingRemoteDataSourceProvider = Provider<BuildingRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BuildingRemoteDataSource(apiClient);
});

/// ===================================
/// Repository Providers
/// ===================================

/// BuildingRepository Provider
final buildingRepositoryProvider = Provider<BuildingRepository>((ref) {
  final dataSource = ref.watch(buildingRemoteDataSourceProvider);
  return BuildingRepositoryImpl(dataSource);
});

/// ===================================
/// UseCase Providers
/// ===================================

/// 건물 등록 UseCase Provider
final createBuildingUseCaseProvider = Provider<CreateBuildingUseCase>((ref) {
  final repository = ref.watch(buildingRepositoryProvider);
  return CreateBuildingUseCase(repository);
});

/// 건물 목록 조회 UseCase Provider
final getBuildingsUseCaseProvider = Provider<GetBuildingsUseCase>((ref) {
  final repository = ref.watch(buildingRepositoryProvider);
  return GetBuildingsUseCase(repository);
});

/// ===================================
/// Department Providers
/// ===================================

/// 부서 목록 새로고침 트리거
final departmentRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 부서 목록 조회 상태 관리
/// refreshTrigger를 의존성으로 추가하여 상태 변경 시 자동 새로고침
final departmentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String?>((ref, keyword) async {
  // refreshTrigger를 감시 - 이 값이 변경되면 Provider 재실행
  ref.watch(departmentRefreshTriggerProvider);

  final dataSource = ref.watch(departmentRemoteDataSourceProvider);
  final response = await dataSource.getDepartments(keyword: keyword);

  if (response['success'] == true) {
    final data = response['data'];
    return List<Map<String, dynamic>>.from(data['items'] ?? []);
  }

  throw Exception('부서 목록을 불러오는 중 오류가 발생했습니다.');
});

/// ===================================
/// Building Providers
/// ===================================

/// 건물 목록 새로고침 트리거
final buildingRefreshTriggerProvider = StateProvider<int>((ref) => 0);

/// 건물 목록 조회 상태 관리
/// refreshTrigger를 의존성으로 추가하여 상태 변경 시 자동 새로고침
final buildingsProvider = FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>?>((ref, params) async {
  // refreshTrigger를 감시 - 이 값이 변경되면 Provider 재실행
  ref.watch(buildingRefreshTriggerProvider);

  final dataSource = ref.watch(buildingRemoteDataSourceProvider);
  final response = await dataSource.getBuildings(
    keyword: params?['keyword'],
    headquartersId: params?['headquartersId'],
  );

  if (response['success'] == true) {
    final data = response['data'];
    return List<Map<String, dynamic>>.from(data['items'] ?? []);
  }

  throw Exception('건물 목록을 불러오는 중 오류가 발생했습니다.');
});

/// ===================================
/// 참고: Admin 관련 Provider는
/// 동일한 패턴으로 추가 가능합니다.
/// ===================================

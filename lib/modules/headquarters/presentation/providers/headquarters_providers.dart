import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/building_remote_datasource.dart';
import 'package:building_manage_front/modules/headquarters/data/repositories/building_repository_impl.dart';
import 'package:building_manage_front/modules/headquarters/domain/repositories/building_repository.dart';
import 'package:building_manage_front/modules/headquarters/domain/usecases/create_building_usecase.dart';
import 'package:building_manage_front/modules/headquarters/domain/usecases/get_buildings_usecase.dart';
import 'package:building_manage_front/core/network/api_client.dart';

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
/// 참고: Department 및 Admin 관련 Provider는
/// 동일한 패턴으로 추가 가능합니다.
/// ===================================

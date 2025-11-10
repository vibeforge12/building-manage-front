import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';

/// 부서 목록 상태
class DepartmentListState {
  final List<Map<String, dynamic>> departments;
  final bool isLoading;
  final String? error;

  DepartmentListState({
    this.departments = const [],
    this.isLoading = false,
    this.error,
  });

  DepartmentListState copyWith({
    List<Map<String, dynamic>>? departments,
    bool? isLoading,
    String? error,
  }) {
    return DepartmentListState(
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 부서 목록 관리 Notifier
class DepartmentListNotifier extends StateNotifier<DepartmentListState> {
  final DepartmentRemoteDataSource _dataSource;

  DepartmentListNotifier(this._dataSource) : super(DepartmentListState());

  /// 부서 목록 불러오기
  Future<void> fetchDepartments({
    int page = 1,
    int limit = 100,
    String? keyword,
    String? headquartersId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _dataSource.getDepartments(
        page: page,
        limit: limit,
        sortOrder: 'DESC',
        keyword: keyword,
        headquartersId: headquartersId,
      );

      final data = response['data'] as Map<String, dynamic>?;
      if (data != null) {
        final items = data['items'] as List<dynamic>? ?? [];
        final departments = items
            .map((item) => item as Map<String, dynamic>)
            .toList();

        state = state.copyWith(
          departments: departments,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: '부서 목록을 불러올 수 없습니다.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 상태 초기화
  void reset() {
    state = DepartmentListState();
  }
}

/// 부서 목록 Provider
final departmentListProvider =
    StateNotifierProvider<DepartmentListNotifier, DepartmentListState>((ref) {
  final dataSource = ref.watch(departmentRemoteDataSourceProvider);
  return DepartmentListNotifier(dataSource);
});

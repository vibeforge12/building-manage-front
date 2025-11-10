import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() => _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  List<Map<String, dynamic>> _staffs = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _buildingName;

  @override
  void initState() {
    super.initState();
    _loadStaffs();
    _loadBuildingName();
  }

  void _loadBuildingName() {
    // 현재 로그인한 관리자의 이름을 건물명으로 사용
    final currentUser = ref.read(currentUserProvider);
    if (currentUser != null) {
      setState(() {
        _buildingName = currentUser.name;
      });
    }
  }

  Future<void> _loadStaffs() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staffDataSource = ref.read(staffRemoteDataSourceProvider);
      final response = await staffDataSource.getStaffs();

      if (response['success'] == true) {
        setState(() {
          _staffs = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '담당자 목록을 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '담당자 관리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadStaffs,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : _staffs.isEmpty
                  ? const Center(
                      child: Text(
                        '등록된 담당자가 없습니다.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : _buildStaffList(),
    );
  }

  Widget _buildStaffList() {
    // 부서별로 담당자 그룹화
    final Map<String, List<Map<String, dynamic>>> groupedStaffs = {};

    for (final staff in _staffs) {
      final department = staff['department'] as Map<String, dynamic>?;
      final departmentName = department?['name'] ?? '부서 없음';

      if (!groupedStaffs.containsKey(departmentName)) {
        groupedStaffs[departmentName] = [];
      }
      groupedStaffs[departmentName]!.add(staff);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 담당자 리스트
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            itemCount: groupedStaffs.length,
            itemBuilder: (context, index) {
              final departmentName = groupedStaffs.keys.elementAt(index);
              final staffsInDept = groupedStaffs[departmentName]!;

              return Column(
                children: staffsInDept.map((staff) {
                  return _buildStaffItem(
                    departmentName: departmentName,
                    staff: staff,
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStaffItem({
    required String departmentName,
    required Map<String, dynamic> staff,
  }) {
    final name = staff['name'] ?? '이름 없음';
    final staffId = staff['id']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          // 부서명과 이름
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 부서명
                Text(
                  departmentName,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF17191A),
                  ),
                ),
                const SizedBox(height: 4),
                // 이름
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF757B80),
                  ),
                ),
              ],
            ),
          ),
          // 액션 버튼들
          Row(
            children: [
              // 삭제 버튼
              GestureDetector(
                onTap: () {
                  // TODO: 삭제 기능
                  print('담당자 삭제: $staffId');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFE8EEF2),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF464A4D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 수정 버튼
              GestureDetector(
                onTap: () {
                  // TODO: 수정 기능
                  print('담당자 수정: $staffId');
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF9FF),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '수정',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF0683FF),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

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
      // UseCase를 통한 담당자 목록 조회 (비즈니스 로직 포함)
      final getStaffsUseCase = ref.read(getStaffsUseCaseProvider);
      final staffs = await getStaffsUseCase.execute();

      setState(() {
        _staffs = staffs.map((staff) => staff.toJson()).toList();
      });
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = e.toString();
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteStaff(String staffId, String staffName) async {
    print('🗑️ _deleteStaff 호출: staffId=$staffId, staffName=$staffName');

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      content: Text(
        '$staffName 담당자를 삭제하시겠습니까?',
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 14,
          color: Color(0xFF464A4D),
        ),
      ),
      confirmText: '삭제',
      cancelText: '취소',
      isDestructive: true,
    );

    print('✅ 다이얼로그 결과: confirmed=$confirmed');

    if (confirmed != true) {
      print('❌ 삭제 취소됨');
      return;
    }

    print('🔄 삭제 진행 시작...');

    try {
      // UseCase를 통한 담당자 삭제 (비즈니스 로직 포함)
      final deleteStaffUseCase = ref.read(deleteStaffUseCaseProvider);
      print('📤 deleteStaffUseCase 호출 중...');
      await deleteStaffUseCase.execute(staffId: staffId);

      print('✅ 삭제 성공!');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('담당자가 삭제되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        print('🔄 목록 새로고침 시작...');
        // 목록 새로고침
        await _loadStaffs();
        print('✅ 목록 새로고침 완료!');
      }
    } catch (e) {
      print('❌ 삭제 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is ApiException
                  ? e.userFriendlyMessage
                  : '담당자 삭제 중 오류가 발생했습니다.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                  _deleteStaff(staffId, name);
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
                onTap: () async {
                  final result = await context.push('/admin/staff-edit/$staffId');
                  // 수정 성공 시 목록 새로고침
                  if (result == true && mounted) {
                    _loadStaffs();
                  }
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

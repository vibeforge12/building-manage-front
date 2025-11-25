import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/headquarters/presentation/providers/headquarters_providers.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class BuildingManagementScreen extends ConsumerStatefulWidget {
  const BuildingManagementScreen({super.key});

  @override
  ConsumerState<BuildingManagementScreen> createState() => _BuildingManagementScreenState();
}

class _BuildingManagementScreenState extends ConsumerState<BuildingManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _editDepartment(String departmentId, String currentName) async {
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _EditDepartmentDialog(
          currentName: currentName,
        );
      },
    );

    if (result == null || result.isEmpty || result == currentName) {
      return;
    }

    // Dialog 종료 후 안정적인 상태에서 API 호출
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) return;

    try {
      final departmentDataSource = ref.read(departmentRemoteDataSourceProvider);
      final response = await departmentDataSource.updateDepartment(
        departmentId: departmentId,
        name: result,
      );

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('부서가 수정되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 부서 목록 새로고침 트리거
          ref.read(departmentRefreshTriggerProvider.notifier).state++;
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('부서 수정 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteDepartment(String departmentId, String departmentName) async {
    // 삭제 확인 다이얼로그
    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '삭제를 진행하시겠습니까?',
      content: const SizedBox.shrink(),
      confirmText: '예',
      cancelText: '아니오',
      confirmOnLeft: true,
      barrierDismissible: false,
    );

    if (confirmed != true) return;

    try {
      final departmentDataSource = ref.read(departmentRemoteDataSourceProvider);
      final response = await departmentDataSource.deleteDepartment(departmentId);

      if (mounted) {
        if (response['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('부서가 삭제되었습니다.'),
              backgroundColor: Colors.green,
            ),
          );
          // 부서 목록 새로고침 트리거
          ref.read(departmentRefreshTriggerProvider.notifier).state++;
        }
      }
    } catch (e) {
      if (mounted) {
        // 에러 팝업 표시
        await showCustomConfirmationDialog(
          context: context,
          title: '',
          content: Text(
            '삭제되지 않은 \n 담당자 계정이 존재합니다.',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          confirmText: '확인',
          cancelText: '',
          barrierDismissible: false,
          confirmOnLeft: true,
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
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/headquarters/dashboard');
            }
          },
        ),
        title: const Text(
          '부서 관리',
          style: TextStyle(
            color: Color(0xFF464A4D),
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.push('/headquarters/department-creation');
            },
            child: const Text(
              '등록',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF464A4D),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
          ),
        ),
        centerTitle: true,
      ),
      body: Consumer(
        builder: (context, ref, child) {
          final departmentsFuture = ref.watch(departmentsProvider(null));

          return departmentsFuture.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error.toString(), style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.refresh(departmentsProvider(null));
                    },
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            ),
            data: (departments) {
              if (departments.isEmpty) {
                return const Center(
                  child: Text(
                    '등록된 부서가 없습니다.',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: departments.length,
                itemBuilder: (context, index) {
                  final department = departments[index];
                  final departmentId = department['id']?.toString() ?? '';
                  final departmentName = department['name'] ?? '부서명 없음';

                  return GestureDetector(
                    onTap: () {
                      if (departmentId.isNotEmpty) {
                        _editDepartment(departmentId, departmentName);
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFFE8EEF2),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // 부서명
                          Expanded(
                            child: Text(
                              departmentName,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // 삭제 버튼
                          InkWell(
                            onTap: () {
                              if (departmentId.isNotEmpty) {
                                _deleteDepartment(departmentId, departmentName);
                              }
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: const Color(0xFFE8EEF2),
                                  width: 1,
                                ),
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
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _EditDepartmentDialog extends StatefulWidget {
  final String currentName;

  const _EditDepartmentDialog({required this.currentName});

  @override
  State<_EditDepartmentDialog> createState() => _EditDepartmentDialogState();
}

class _EditDepartmentDialogState extends State<_EditDepartmentDialog> {
  late final TextEditingController _editController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.currentName);
    _focusNode = FocusNode();

    // 키보드 열기
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.unfocus();
    _focusNode.dispose();
    _editController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text(
        '부서명 수정',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF17191A),
        ),
        textAlign: TextAlign.center,
      ),
      content: TextField(
        controller: _editController,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: '부서명을 입력해주세요',
          hintStyle: const TextStyle(color: Colors.grey),
          filled: true,
          fillColor: const Color(0xFFF8F9FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFE8EEF2),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFFE8EEF2),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Color(0xFF006FFF),
              width: 1.5,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          color: Color(0xFF17191A),
        ),
        onSubmitted: (_) {
          _focusNode.unfocus();
          Navigator.of(context).pop(_editController.text.trim());
        },
      ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  _focusNode.unfocus();
                  Navigator.of(context).pop();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  '취소',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF757B80),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextButton(
                onPressed: () {
                  _focusNode.unfocus();
                  Navigator.of(context).pop(_editController.text.trim());
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF006FFF),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
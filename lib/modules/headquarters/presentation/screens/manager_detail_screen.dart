import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/common/data/datasources/manager_list_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class ManagerDetailScreen extends ConsumerStatefulWidget {
  final String managerId;

  const ManagerDetailScreen({
    super.key,
    required this.managerId,
  });

  @override
  ConsumerState<ManagerDetailScreen> createState() => _ManagerDetailScreenState();
}

class _ManagerDetailScreenState extends ConsumerState<ManagerDetailScreen> {
  Map<String, dynamic>? _managerData;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _isDeleting = false;
  String? _errorMessage;

  // 수정 모드 상태
  bool _isEditMode = false;

  // 수정용 컨트롤러
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // 원본 값 (변경 감지용)
  String _originalName = '';
  String _originalPhone = '';

  @override
  void initState() {
    super.initState();
    _loadManagerDetail();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// 수정사항이 있는지 확인
  bool get _hasChanges {
    return _nameController.text != _originalName ||
        _phoneController.text != _originalPhone;
  }

  Future<void> _loadManagerDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final managerDataSource = ref.read(managerListRemoteDataSourceProvider);
      final response = await managerDataSource.getManagerDetail(widget.managerId);

      if (response['success'] == true) {
        setState(() {
          _managerData = response['data'] as Map<String, dynamic>;
          // 컨트롤러 초기화
          _nameController.text = _managerData?['name'] ?? '';
          _phoneController.text = _managerData?['phoneNumber'] ?? '';
          // 원본 값 저장
          _originalName = _nameController.text;
          _originalPhone = _phoneController.text;
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '관리자 정보를 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 수정 모드 토글
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        // 수정 모드 취소 시 원본 값으로 복원
        _nameController.text = _originalName;
        _phoneController.text = _originalPhone;
      }
    });
  }

  /// 저장 처리
  Future<void> _saveChanges() async {
    if (!_hasChanges) {
      setState(() {
        _isEditMode = false;
      });
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final managerDataSource = ref.read(managerListRemoteDataSourceProvider);
      final response = await managerDataSource.updateManager(
        managerId: widget.managerId,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );

      if (response['success'] == true) {
        // 저장 성공
        setState(() {
          _originalName = _nameController.text;
          _originalPhone = _phoneController.text;
          _isEditMode = false;
          // _managerData 업데이트
          if (_managerData != null) {
            _managerData!['name'] = _nameController.text;
            _managerData!['phoneNumber'] = _phoneController.text;
          }
        });

        if (mounted) {
          // 관리자 정보 저장 성공
        }
      }
    } catch (e) {
      // 저장 실패
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /// 뒤로가기 처리 (수정사항 확인)
  Future<bool> _onWillPop() async {
    if (_isEditMode && _hasChanges) {
      final result = await _showExitConfirmDialog();
      return result ?? false;
    }
    return true;
  }

  /// 수정사항 확인 모달
  Future<bool?> _showExitConfirmDialog() {
    return showCustomConfirmationDialog(
      context: context,
      title: '변경사항이 저장되지 않습니다.\n나가시겠습니까?',
      content: const SizedBox.shrink(),
      confirmText: '예',
      cancelText: '아니오',
      barrierDismissible: false,
      confirmOnLeft: false,  // "예"를 오른쪽에 배치
    );
  }

  /// 관리자 삭제 확인 다이얼로그
  Future<void> _showDeleteConfirmDialog() async {
    final managerName = _managerData?['name'] ?? '관리자';

    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '관리자 삭제',
      content: Text(
        '$managerName 관리자를\n정말 삭제하시겠습니까?\n\n삭제된 계정은 복구할 수 없습니다.',
        textAlign: TextAlign.center,
      ),
      confirmText: '삭제',
      cancelText: '취소',
      isDestructive: true,
      barrierDismissible: false,
      confirmOnLeft: false,  // "삭제"를 오른쪽에 배치
    );

    if (confirmed == true && mounted) {
      await _executeDelete();
    }
  }

  /// 관리자 삭제 실행
  Future<void> _executeDelete() async {
    setState(() {
      _isDeleting = true;
    });

    try {
      final managerDataSource = ref.read(managerListRemoteDataSourceProvider);
      final response = await managerDataSource.deleteManager(widget.managerId);

      if (response['success'] == true && mounted) {
        // 먼저 목록으로 돌아가기 (삭제 완료 신호 전달)
        context.pop({'deleted': true, 'message': '관리자가 삭제되었습니다.'});
      }
    } catch (e) {
      // 관리자 삭제 실패
      debugPrint('❌ Manager Delete Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final building = _managerData?['building'] as Map<String, dynamic>?;
    final buildingName = building?['name'] ?? '';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final canPop = await _onWillPop();
        if (canPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () async {
              final canPop = await _onWillPop();
              if (canPop && context.mounted) {
                context.pop();
              }
            },
          ),
          title: Text(
            buildingName,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF464A4D),
            ),
          ),
          centerTitle: true,
          actions: [
            // 수정/저장 버튼
            if (_managerData != null)
              _isSaving
                  ? const Padding(
                      padding: EdgeInsets.only(right: 16),
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : TextButton(
                      onPressed: _isEditMode ? _saveChanges : _toggleEditMode,
                      child: Text(
                        _isEditMode ? '저장' : '수정',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: _isEditMode
                              ? const Color(0xFF4B7BF5)
                              : const Color(0xFF464A4D),
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
                          onPressed: _loadManagerDetail,
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  )
                : _managerData == null
                    ? const Center(child: Text('관리자 정보를 찾을 수 없습니다.'))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 섹션 헤더
                            Container(
                              width: double.infinity,
                              height: 44,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              child: const Text(
                                '관리자',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: Color(0xFF17191A),
                                ),
                              ),
                            ),
                            // 정보 필드들
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 이름 필드 (수정 가능)
                                  _buildEditableField(
                                    label: '이름',
                                    controller: _nameController,
                                    isEditable: _isEditMode,
                                  ),
                                  const SizedBox(height: 16),
                                  // 전화번호 필드 (수정 가능)
                                  _buildEditableField(
                                    label: '전화번호',
                                    controller: _phoneController,
                                    isEditable: _isEditMode,
                                    keyboardType: TextInputType.phone,
                                  ),
                                  const SizedBox(height: 16),
                                  // 관리자 코드 필드 (수정 불가)
                                  _buildInfoField(
                                    label: '관리자 코드',
                                    value: _managerData?['managerCode'] ?? '',
                                  ),
                                  const SizedBox(height: 32),
                                  // 삭제 버튼
                                  _buildDeleteButton(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
      ),
    );
  }

  /// 수정 가능한 필드 빌더
  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required bool isEditable,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF464A4D),
            height: 1.67,
          ),
        ),
        const SizedBox(height: 4),
        // 값 컨테이너 또는 TextField
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isEditable ? Colors.white : const Color(0xFFF9FAFB),
            border: Border.all(
              color: isEditable ? const Color(0xFF4B7BF5) : const Color(0xFFE8EEF2),
              width: isEditable ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: isEditable
              ? TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Color(0xFF464A4D),
                    height: 1.5,
                  ),
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.all(8),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    controller.text,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF464A4D),
                      height: 1.5,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  /// 읽기 전용 필드 빌더 (관리자 코드용)
  Widget _buildInfoField({
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 라벨
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 12,
            color: Color(0xFF464A4D),
            height: 1.67,
          ),
        ),
        const SizedBox(height: 4),
        // 값 컨테이너
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(
              color: const Color(0xFFE8EEF2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Color(0xFF9CA3AF),
                    height: 1.5,
                  ),
                ),
              ),
              const Icon(
                Icons.lock_outline,
                size: 16,
                color: Color(0xFF9CA3AF),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 삭제 버튼 빌더
  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _isDeleting ? null : _showDeleteConfirmDialog,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFFF3B30),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: _isDeleting
            ? const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF3B30)),
                  ),
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline,
                    size: 20,
                    color: Color(0xFFFF3B30),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '관리자 삭제',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

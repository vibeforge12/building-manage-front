import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';

class NoticeCreateScreen extends ConsumerStatefulWidget {
  final bool isEvent;

  const NoticeCreateScreen({
    super.key,
    this.isEvent = false,
  });

  @override
  ConsumerState<NoticeCreateScreen> createState() => _NoticeCreateScreenState();
}

class _NoticeCreateScreenState extends ConsumerState<NoticeCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _selectedTarget = 'BOTH'; // 전체
  String? _selectedDepartmentId;
  String _selectedDepartmentName = '부서 선택';

  List<Map<String, dynamic>> _departments = [];
  bool _isDepartmentsLoading = false;

  // 모든 필드가 채워졌는지 확인
  bool get _isFormValid {
    return _selectedDepartmentId != null &&
        _titleController.text.trim().isNotEmpty &&
        _contentController.text.trim().isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _loadDepartments();

    // 텍스트 변경 시 UI 업데이트
    _titleController.addListener(_updateFormState);
    _contentController.addListener(_updateFormState);
  }

  void _updateFormState() {
    setState(() {
      // 폼 상태가 변경되면 UI 재빌드
    });
  }

  @override
  void dispose() {
    _titleController.removeListener(_updateFormState);
    _contentController.removeListener(_updateFormState);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isDepartmentsLoading = true;
    });

    try {
      final departmentDataSource = ref.read(departmentRemoteDataSourceProvider);
      final response = await departmentDataSource.getDepartments(
        limit: 100,
        status: 'ACTIVE',
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      print('부서 목록 조회 패: $e');
    } finally {
      setState(() {
        _isDepartmentsLoading = false;
      });
    }
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('부서를 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // TODO: API 연동
    final noticeData = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'target': _selectedTarget,
      'departmentId': _selectedDepartmentId,
      'imageUrl': null, // 이미지 업로드 기능 추가 시 구현
    };

    print('공지사항 등록: $noticeData');

    // TODO: POST /api/v1/managers/notices API 호출
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.isEvent ? '이벤트' : '공지사항'}이 등록되었습니다.'),
        backgroundColor: Colors.green,
      ),
    );

    context.pop();
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
        title: Text(
          widget.isEvent ? '이벤트 등록' : '공지 등록',
          style: const TextStyle(
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
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 유저 섹션 드롭다운
                    PopupMenuButton<String>(
                      initialValue: _selectedTarget,
                      offset: const Offset(0, 48),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'BOTH',
                          child: Text(
                            '전체',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'RESIDENT',
                          child: Text(
                            '유저',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'STAFF',
                          child: Text(
                            '담당자',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        setState(() {
                          _selectedTarget = value;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE8EEF2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getTargetLabel(),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 24,
                              color: Color(0xFF17191A),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // 부서 드롭다운
                    PopupMenuButton<String>(
                      enabled: !_isDepartmentsLoading && _departments.isNotEmpty,
                      offset: const Offset(0, 48),
                      color: Colors.white,
                      surfaceTintColor: Colors.white,
                      constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width,
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      itemBuilder: (context) => _departments.map((dept) {
                        return PopupMenuItem(
                          value: dept['id'] as String,
                          child: Text(
                            dept['name'] as String,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        );
                      }).toList(),
                      onSelected: (value) {
                        setState(() {
                          _selectedDepartmentId = value;
                          _selectedDepartmentName = _departments
                              .firstWhere((dept) => dept['id'] == value)['name'] as String;
                        });
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFE8EEF2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _selectedDepartmentName,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                            _isDepartmentsLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(
                                    Icons.keyboard_arrow_down,
                                    size: 24,
                                    color: Color(0xFF17191A),
                                  ),
                          ],
                        ),
                      ),
                    ),

                    // 제목 및 내용 입력
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 제목
                          TextFormField(
                            controller: _titleController,
                            decoration: const InputDecoration(
                              hintText: '제목 입력란',
                              hintStyle: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                fontSize: 20,
                                color: Color(0xFFA4ADB2),
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFF17191A),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '제목을 입력해주세요';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFE8EEF2)),
                          const SizedBox(height: 8),
                          // 내용
                          TextFormField(
                            controller: _contentController,
                            decoration: const InputDecoration(
                              hintText: '내용을 입력하세요.',
                              hintStyle: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                color: Color(0xFFA4ADB2),
                                height: 1.8,
                              ),
                              border: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Color(0xFF17191A),
                              height: 1.8,
                            ),
                            maxLines: 10,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return '내용을 입력해주세요';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 등록 버튼
            Container(
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isFormValid ? _submitNotice : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: _isFormValid
                        ? const Color(0xFF006FFF)
                        : const Color(0xFFE8EEF2),
                    disabledBackgroundColor: const Color(0xFFE8EEF2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    '등록하기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: _isFormValid
                          ? Colors.white
                          : const Color(0xFFA4ADB2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTargetLabel() {
    switch (_selectedTarget) {
      case 'BOTH':
        return '전체';
      case 'RESIDENT':
        return '유저';
      case 'STAFF':
        return '담당자';
      default:
        return '전체';
    }
  }
}

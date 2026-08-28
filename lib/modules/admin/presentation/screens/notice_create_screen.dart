import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';

class NoticeCreateScreen extends ConsumerStatefulWidget {
  final bool isEvent;
  final String? noticeId;

  const NoticeCreateScreen({
    super.key,
    this.isEvent = false,
    this.noticeId,
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
  bool _isEditing = false;
  String? _existingImageUrl;

  // 모든 필드가 채워졌는지 확인
  bool get _isFormValid {
    final hasTitle = _titleController.text.trim().isNotEmpty;
    final hasContent = _contentController.text.trim().isNotEmpty;

    // 이벤트는 부서 선택 불필요
    if (widget.isEvent) {
      return hasTitle && hasContent;
    }

    // 공지사항: 담당자(STAFF) 대상일 때 부서 선택은 선택적
    // "전체 부서"(departmentId 없음) 또는 특정 부서 선택 가능
    if (_selectedTarget == 'STAFF') {
      return hasTitle && hasContent;
    }

    // 전체(BOTH) 또는 유저(RESIDENT)는 부서 선택 불필요
    return hasTitle && hasContent;
  }

  @override
  void initState() {
    super.initState();
    _loadDepartments();

    // 수정 모드인 경우 기존 데이터 로드
    if (widget.noticeId != null) {
      _loadNoticeDetail();
    }

    // 텍스트 변경 시 UI 업데이트
    _titleController.addListener(_updateFormState);
    _contentController.addListener(_updateFormState);
  }

  Future<void> _loadNoticeDetail() async {
    if (widget.noticeId == null) return;

    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = widget.isEvent
          ? await noticeDataSource.getEventDetail(widget.noticeId!)
          : await noticeDataSource.getNoticeDetail(widget.noticeId!);

      final responseData = response['data'];
      final data = responseData is Map && responseData.containsKey('data')
          ? responseData['data']
          : responseData;

      if (mounted) {
        setState(() {
          _isEditing = true;
          _titleController.text = data['title'] as String? ?? '';
          _contentController.text = data['content'] as String? ?? '';

          if (data['imageUrl'] != null) {
            _existingImageUrl = data['imageUrl'] as String;
          }

          if (!widget.isEvent) {
            _selectedTarget = data['target'] as String? ?? 'BOTH';

            final departmentObj = data['department'];
            if (departmentObj != null && departmentObj is Map) {
              final deptId = departmentObj['id'] as String?;
              final deptName = departmentObj['name'] as String?;

              if (deptId != null) {
                _selectedDepartmentId = deptId;
                _selectedDepartmentName = deptName ?? '부서 선택';
              }
            }
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '불러오기 실패',
        error: e,
        fallback: '내용을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
      if (mounted) {
        context.pop();
      }
    }
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
      // 부서 목록이 비면 담당자 대상 공지를 만들 수 없으므로 사용자에게 알린다.
      if (mounted) {
        await showErrorAlert(
          context,
          title: '부서 목록 조회 실패',
          error: e,
          fallback: '부서 목록을 불러오지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDepartmentsLoading = false;
        });
      }
    }
  }

  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // BOTH 또는 RESIDENT 선택 시 departmentId를 보내면 백엔드 400 에러
    // STAFF + "전체 부서"(ALL) 선택 시에도 departmentId를 보내지 않음

    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);

      // STAFF + 특정 부서일 때만 departmentId 전송
      // BOTH/RESIDENT이거나 "전체 부서"(ALL) 선택 시 null
      final effectiveDepartmentId =
          (_selectedTarget == 'STAFF' &&
           _selectedDepartmentId != null &&
           _selectedDepartmentId != 'ALL')
              ? _selectedDepartmentId
              : null;

      if (_isEditing && widget.noticeId != null) {
        // 수정 모드
        if (widget.isEvent) {
          await noticeDataSource.updateEvent(
            eventId: widget.noticeId!,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            imageUrl: _existingImageUrl,
          );
        } else {
          await noticeDataSource.updateNotice(
            noticeId: widget.noticeId!,
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            target: _selectedTarget,
            departmentId: effectiveDepartmentId,
            imageUrl: _existingImageUrl,
          );
        }
      } else {
        // 등록 모드
        if (widget.isEvent) {
          await noticeDataSource.createEvent(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            imageUrl: _existingImageUrl,
          );
        } else {
          await noticeDataSource.createNotice(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            target: _selectedTarget,
            departmentId: effectiveDepartmentId,
            imageUrl: _existingImageUrl,
          );
        }
      }

      if (mounted) {
        context.pop(true);  // true를 반환하여 목록 새로고침 신호
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: _isEditing ? '수정 실패' : '등록 실패',
        error: e,
        fallback: '요청을 처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
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
        title: Text(
          _isEditing
              ? (widget.isEvent ? '이벤트 수정' : '공지 수정')
              : (widget.isEvent ? '이벤트 등록' : '공지 등록'),
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
      // 하단 고정 버튼·마지막 목록 항목이 시스템 내비게이션 바에 가리지 않도록 감싼다.
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // 유저 섹션 드롭다운
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownMenu<String>(
                              initialSelection: _selectedTarget,
                              width: MediaQuery.of(context).size.width - 32,
                              menuHeight: 300,
                              menuStyle: MenuStyle(
                                backgroundColor: WidgetStateProperty.all(Colors.white),
                                surfaceTintColor: WidgetStateProperty.all(Colors.white),
                              ),
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: const Color(0xFFF2F8FC),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8EEF2),
                                    width: 1,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFE8EEF2),
                                    width: 1,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              dropdownMenuEntries: const [
                                DropdownMenuEntry<String>(
                                  value: 'BOTH',
                                  label: '전체',
                                ),
                                DropdownMenuEntry<String>(
                                  value: 'RESIDENT',
                                  label: '유저',
                                ),
                                DropdownMenuEntry<String>(
                                  value: 'STAFF',
                                  label: '담당자',
                                ),
                              ],
                              onSelected: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedTarget = value;
                                    // 담당자가 아닌 경우 부서 선택 초기화
                                    if (value != 'STAFF') {
                                      _selectedDepartmentId = null;
                                      _selectedDepartmentName = '부서 선택';
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // 부서 드롭다운 (담당자 선택 시에만 표시)
                      if (!widget.isEvent && _selectedTarget == 'STAFF')
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              _isDepartmentsLoading
                                  ? Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF2F8FC),
                                      border: Border.all(
                                        color: const Color(0xFFE8EEF2),
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '부서 목록 불러오는 중...',
                                          style: TextStyle(
                                            fontFamily: 'Pretendard',
                                            fontWeight: FontWeight.w400,
                                            fontSize: 16,
                                            color: Color(0xFF757B80),
                                          ),
                                        ),
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                      ],
                                    ),
                                  )
                                : DropdownMenu<String>(
                                    initialSelection: _selectedDepartmentId,
                                    width: MediaQuery.of(context).size.width - 32,
                                    menuHeight: 300,
                                    menuStyle: MenuStyle(
                                      backgroundColor: WidgetStateProperty.all(Colors.white),
                                      surfaceTintColor: WidgetStateProperty.all(Colors.white),
                                    ),
                                    inputDecorationTheme: InputDecorationTheme(
                                      filled: true,
                                      fillColor: const Color(0xFFF2F8FC),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE8EEF2),
                                          width: 1,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Color(0xFFE8EEF2),
                                          width: 1,
                                        ),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                    ),
                                    dropdownMenuEntries: [
                                      const DropdownMenuEntry<String>(
                                        value: 'ALL',
                                        label: '전체 부서',
                                      ),
                                      ..._departments.map((dept) {
                                        return DropdownMenuEntry<String>(
                                          value: dept['id'] as String,
                                          label: dept['name'] as String,
                                        );
                                      }),
                                    ],
                                    onSelected: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedDepartmentId = value;
                                          _selectedDepartmentName = _departments
                                              .firstWhere((dept) => dept['id'] == value)['name']
                                              as String;
                                        });
                                      }
                                    },
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

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
                      _isEditing ? '수정하기' : '등록하기',
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
      ),
    );
  }

}

import 'package:flutter/material.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/push_opt_in_checkbox.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

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

  /// 이미 있는 글을 열었을 때는 '읽기' 로 시작한다(공고문 화면과 같은 규칙).
  /// 목록에서 눌렀다고 바로 고쳐지면 확인만 하려던 글이 바뀔 수 있다.
  /// 고치려면 '수정' 을 한 번 더 눌러야 한다.
  late bool _readOnly = widget.noticeId != null;

  /// 등록할 때 입주민에게 알림을 보낼지. 공고문과 같은 규칙으로 기본은 꺼짐이다.
  /// 지금까지 공지·이벤트는 올릴 때마다 무조건 울렸는데, 그러면 입주민이
  /// 앱 알림 자체를 꺼버려 정작 급한 공지가 닿지 않는다.
  bool _sendPush = false;
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
            sendPush: _sendPush,
          );
        } else {
          await noticeDataSource.createNotice(
            title: _titleController.text.trim(),
            content: _contentController.text.trim(),
            target: _selectedTarget,
            departmentId: effectiveDepartmentId,
            imageUrl: _existingImageUrl,
            sendPush: _sendPush,
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
    // 상단 제목은 건물명이다. 관리 화면(공지사항·공고문)과 같은 골격으로,
    // "어느 건물에 쓰는 글인지" 를 먼저 보이고 무엇을 쓰는 중인지는 아랫줄에 적는다.
    // 관리자·담당자는 건물이 하나뿐이라 이 값이 항상 채워진다.
    final buildingName = ref.watch(currentUserProvider)?.buildingName;
    final what = widget.isEvent ? '이벤트' : '공지';
    final actionLabel = widget.noticeId == null
        ? '$what 등록'
        : (_readOnly ? what : '$what 수정');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        // 건물명을 못 받은 경우에는 자리표시자를 내보내지 않고 하던 대로 동작 이름을 쓴다.
        title: Text(
          buildingName ?? actionLabel,
          // 건물명이 길면 두 줄이 되어 AppBar 높이가 늘어난다. 한 줄로 자른다.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        actions: [
          // 읽는 중일 때만 나온다. 누르면 이 화면이 그대로 편집 상태가 된다.
          if (_readOnly)
            TextButton(
              onPressed: () => setState(() => _readOnly = false),
              child: const Text(
                '수정',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF464A4D),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(buildingName == null ? 1 : 55),
          child: Column(
            children: [
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              if (buildingName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 60,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      // SafeArea 가 없어 하단 '등록하기/수정하기' 버튼이 시스템 내비게이션 바에 가려졌다.
      // 목록처럼 스크롤되는 화면은 티가 안 나지만, 하단에 고정된 버튼은 그대로 잘린다.
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
                            enabled: !_readOnly,
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
                                  enabled: !_readOnly,
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
                    // 알림 발송 여부. 등록할 때만 고른다 —
                    // 수정으로 다시 보낼 수는 없다(공고문과 같은 규칙).
                    if (widget.noticeId == null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: PushOptInCheckbox(
                          value: _sendPush,
                          onChanged: (value) => setState(() => _sendPush = value),
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
                            readOnly: _readOnly,
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
                            readOnly: _readOnly,
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

            // 등록 버튼. 읽는 중에는 없앤다.
            if (!_readOnly)
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffEditScreen extends ConsumerStatefulWidget {
  final String staffId;

  const StaffEditScreen({
    super.key,
    required this.staffId,
  });

  @override
  ConsumerState<StaffEditScreen> createState() => _StaffEditScreenState();
}

class _StaffEditScreenState extends ConsumerState<StaffEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // 원본 데이터 (수정 시 필요)
  String? _imageUrl;
  String? _departmentId;
  String? _departmentName;
  String? _status;
  String? _staffCode;

  // 부서 목록
  List<Map<String, dynamic>> _departments = [];
  bool _isDepartmentsLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaffDetail();
    _loadDepartments();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadStaffDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // UseCase를 통한 담당자 상세 조회 (비즈니스 로직 포함)
      final getStaffDetailUseCase = ref.read(getStaffDetailUseCaseProvider);
      final staff = await getStaffDetailUseCase.execute(staffId: widget.staffId);

      setState(() {
        _nameController.text = staff.name;
        _phoneController.text = staff.phoneNumber;
        _imageUrl = staff.imageUrl;
        _status = staff.status.toServerString();
        _staffCode = staff.id; // staffCode가 id를 의미하는 것으로 추정

        _departmentId = staff.departmentId;
        _departmentName = staff.departmentName;
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

  Future<void> _loadDepartments() async {
    setState(() {
      _isDepartmentsLoading = true;
    });

    try {
      final departmentDataSource = ref.read(departmentRemoteDataSourceProvider);
      final response = await departmentDataSource.getDepartments(
        limit: 100, // 모든 부서 조회
        status: 'ACTIVE', // 활성 부서만
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      print('부서 목록 조회 실패: $e');
      // 부서 목록 조회 실패는 에러로 표시하지 않고 로그만 출력
    } finally {
      setState(() {
        _isDepartmentsLoading = false;
      });
    }
  }

  Future<void> _saveStaff() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('부서 정보가 없습니다.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // UseCase를 통한 담당자 정보 수정 (비즈니스 로직 포함)
      final updateStaffUseCase = ref.read(updateStaffUseCaseProvider);
      await updateStaffUseCase.execute(
        staffId: widget.staffId,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        imageUrl: _imageUrl,
        departmentId: _departmentId!,
        status: _status ?? 'ACTIVE',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('담당자 정보가 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );

        context.pop(true); // 수정 성공 시 true 반환
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
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
          '담당자 수정',
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
                        onPressed: _loadStaffDetail,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 이름
                              const Text(
                                '이름',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF464A4D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: '이름을 입력하세요',
                                  filled: true,
                                  fillColor: Colors.white,
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006FFF),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '이름을 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // 휴대폰 번호
                              const Text(
                                '휴대폰 번호',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF464A4D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: InputDecoration(
                                  hintText: '010-0000-0000',
                                  filled: true,
                                  fillColor: Colors.white,
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
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Color(0xFF006FFF),
                                      width: 1.5,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return '휴대폰 번호를 입력해주세요';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // 부서
                              const Text(
                                '부서',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF464A4D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              _isDepartmentsLoading
                                  ? Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFFE8EEF2),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : DropdownMenu<String>(
                                      initialSelection: _departmentId,
                                      width: MediaQuery.of(context).size.width - 32,
                                      menuHeight: 300,
                                      requestFocusOnTap: true,
                                      enableFilter: false,
                                      menuStyle: MenuStyle(
                                        backgroundColor: WidgetStateProperty.all(Colors.white),
                                        surfaceTintColor: WidgetStateProperty.all(Colors.white),
                                        elevation: WidgetStateProperty.all(8),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                      textStyle: const TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w400,
                                        fontSize: 16,
                                        color: Color(0xFF464A4D),
                                      ),
                                      inputDecorationTheme: InputDecorationTheme(
                                        filled: true,
                                        fillColor: Colors.white,
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
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF006FFF),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      trailingIcon: const Icon(
                                        Icons.keyboard_arrow_down,
                                        color: Color(0xFF757B80),
                                      ),
                                      selectedTrailingIcon: const Icon(
                                        Icons.keyboard_arrow_up,
                                        color: Color(0xFF006FFF),
                                      ),
                                      dropdownMenuEntries: _departments.map((dept) {
                                        return DropdownMenuEntry<String>(
                                          value: dept['id'] as String,
                                          label: dept['name'] as String,
                                          style: MenuItemButton.styleFrom(
                                            foregroundColor: const Color(0xFF464A4D),
                                            backgroundColor: Colors.white,
                                            textStyle: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 16,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                      onSelected: (value) {
                                        setState(() {
                                          _departmentId = value;
                                          _departmentName = _departments
                                              .firstWhere((dept) => dept['id'] == value)['name'] as String;
                                        });
                                      },
                                    ),

                                  const SizedBox(height: 24),
                                          // 담당자 코드 (읽기 전용)
                              const Text(
                                '담당자 코드',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF464A4D),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
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
                                child: Text(
                                  _staffCode ?? '-',
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 16,
                                    color: Color(0xFF757B80),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 저장 버튼
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(
                          top: BorderSide(
                            color: Color(0xFFE8EEF2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _saveStaff,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF006FFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '저장',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';
import 'package:building_manage_front/shared/widgets/section_divider.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/modules/common/data/datasources/building_list_remote_datasource.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/admin_account_remote_datasource.dart';

class AdminAccountIssuanceScreen extends ConsumerStatefulWidget {
  const AdminAccountIssuanceScreen({super.key});

  @override
  ConsumerState<AdminAccountIssuanceScreen> createState() => _AdminAccountIssuanceScreenState();
}

class _AdminAccountIssuanceScreenState extends ConsumerState<AdminAccountIssuanceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  List<Map<String, dynamic>> _buildings = [];
  Map<String, dynamic>? _selectedBuilding;
  bool _isLoadingBuildings = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBuildings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadBuildings() async {
    setState(() {
      _isLoadingBuildings = true;
      _errorMessage = null;
    });

    try {
      final buildingDataSource = ref.read(buildingListRemoteDataSourceProvider);
      final response = await buildingDataSource.getBuildings(
        limit: 100, // 모든 건물을 가져오기 위해 큰 수로 설정
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _buildings = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '건물 목록을 불러오는 중 오류가 발생했습니다.';
      });
    } finally {
      setState(() {
        _isLoadingBuildings = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedBuilding == null) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final adminAccountDataSource = ref.read(adminAccountRemoteDataSourceProvider);

      final response = await adminAccountDataSource.createAdminAccount(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        buildingId: _selectedBuilding!['id'].toString(),
      );

      if (mounted) {
        // 성공 다이얼로그 표시
        await showCustomConfirmationDialog(
          context: context,
          title: '',
          content: const Text('관리자 계정이 발급 되었습니다.', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w700),),
          confirmText: '확인',
          cancelText: '',
          barrierDismissible: false,
          confirmOnLeft: true,
        );

        // 다이얼로그가 완전히 닫힌 후 본사 메인 화면으로 이동
        if (mounted) {
          // 약간의 딜레이를 줘서 다이얼로그 닫기 애니메이션 완료 대기
          await Future.delayed(const Duration(milliseconds: 200));
          if (mounted) {
            // 본사 대시보드로 명시적 이동
            context.go('/headquarters/dashboard');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        // 에러 다이얼로그 표시
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.error, color: Colors.red, size: 48),
            title: const Text('계정 발급 실패'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
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
          '관리자 계정발급',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: SectionDivider(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 이름 필드
              fieldLabel('이름', context),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: '이름을 입력해주세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '이름을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 전화번호 필드
              fieldLabel('전화번호', context),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  hintText: '전화번호를 입력해주세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '전화번호를 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 건물 선택 필드
              fieldLabel('건물 선택', context),
              const SizedBox(height: 8),
              if (_isLoadingBuildings)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFE8EEF2),
                      width: 1,
                    ),
                  ),
                  child: const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 16),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: Colors.red[600]))),
                      TextButton(
                        onPressed: _loadBuildings,
                        child: const Text('다시 시도'),
                      ),
                    ],
                  ),
                )
              else
                DropdownMenu<String>(
                  initialSelection: _selectedBuilding?['id'] as String?,
                  width: MediaQuery.of(context).size.width - 48,
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
                    fillColor: const Color(0xFFF8F9FA),
                    hintStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
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
                    size: 20,
                    color: Color(0xFF757B80),
                  ),
                  selectedTrailingIcon: const Icon(
                    Icons.keyboard_arrow_up,
                    size: 20,
                    color: Color(0xFF006FFF),
                  ),
                  dropdownMenuEntries: _buildings.map((building) {
                    return DropdownMenuEntry<String>(
                      value: building['id'] as String,
                      label: building['name'] as String,
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
                    if (value != null) {
                      setState(() {
                        _selectedBuilding = _buildings.firstWhere(
                          (building) => building['id'] as String == value,
                        );
                      });
                    }
                  },
                ),

              const SizedBox(height: 40),

              // 계정발급 버튼
              SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  label: _isSubmitting ? '발급 중...' : '계정발급',
                  backgroundColor: const Color(0xFF006FFF),
                  foregroundColor: Colors.white,
                  onPressed: _isSubmitting ? () {} : _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
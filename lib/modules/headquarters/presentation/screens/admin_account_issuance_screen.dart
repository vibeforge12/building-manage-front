import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';
import 'package:building_manage_front/shared/widgets/section_divider.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('건물을 선택해주세요.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      print('🔵 관리자 계정 발급 시작');
      final adminAccountDataSource = ref.read(adminAccountRemoteDataSourceProvider);

      final response = await adminAccountDataSource.createAdminAccount(
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        buildingId: _selectedBuilding!['id'].toString(),
      );

      print('✅ 관리자 계정 발급 성공: $response');

      if (mounted) {
        // 성공 다이얼로그 표시
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('계정 발급 완료'),
            content: const Text(
              '관리자 계정이 발급되었습니다.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17191A),
              ),
            ),

            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // 다이얼로그 닫기
                  context.pop(); // 화면 닫기
                },
                child: const Text('확인'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      print('❌ 관리자 계정 발급 실패: $e');
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
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
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
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('건물 목록을 불러오는 중...'),
                    ],
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
                DropdownButtonFormField<Map<String, dynamic>>(
                  value: _selectedBuilding,
                  decoration: const InputDecoration(
                    hintText: '건물을 선택해주세요',
                    hintStyle: TextStyle(color: Colors.grey),
                    filled: true,
                    fillColor: Color(0xFFF8F9FA),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: _buildings.map((building) {
                    return DropdownMenuItem<Map<String, dynamic>>(
                      value: building,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            building['name'] ?? '건물명 없음',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBuilding = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return '건물을 선택해주세요';
                    }
                    return null;
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
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/headquarters/presentation/providers/headquarters_providers.dart';

class DepartmentCreationScreen extends ConsumerStatefulWidget {
  const DepartmentCreationScreen({super.key});

  @override
  ConsumerState<DepartmentCreationScreen> createState() => _DepartmentCreationScreenState();
}

class _DepartmentCreationScreenState extends ConsumerState<DepartmentCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  File? _selectedIcon;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickIcon() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedIcon = File(image.path);
        });
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '아이콘 선택 실패',
        error: e,
        fallback: '이미지를 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final departmentDataSource = ref.read(departmentRemoteDataSourceProvider);

      final response = await departmentDataSource.createHeadquartersDepartment(
        name: _nameController.text.trim(),
        iconFile: _selectedIcon,
      );

      if (mounted) {
        if (response['success'] == true) {
          // 부서 목록 새로고침 트리거 - BuildingManagementScreen의 부서 목록이 즉시 업데이트됨
          ref.read(departmentRefreshTriggerProvider.notifier).state++;

          context.pop(true);  // true를 반환하여 목록 새로고침 신호
        } else {
          await showErrorAlert(
            context,
            title: '부서 생성 실패',
            message: '부서를 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: '부서 생성 실패',
          error: e,
          fallback: '부서를 생성하지 못했습니다. 잠시 후 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
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
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '부서 생성',
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 부서명 필드
              fieldLabel('이름', context),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: '부서명을 입력해주세요',
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
                    return '부서명을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 아이콘 선택 필드
              fieldLabel('아이콘', context),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickIcon,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedIcon != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedIcon!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              '아이콘을 선택해주세요',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '부서를 나타내는 아이콘 이미지를 업로드하세요',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 40),

              // 생성 버튼
              SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  label: _isLoading ? '생성 중...' : '부서 생성',
                  backgroundColor: const Color(0xFF006FFF),
                  foregroundColor: Colors.white,
                  onPressed: _isLoading ? () {} : _submitForm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';
import 'package:building_manage_front/modules/headquarters/presentation/providers/headquarters_providers.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class BuildingRegistrationScreen extends ConsumerStatefulWidget {
  const BuildingRegistrationScreen({super.key});

  @override
  ConsumerState<BuildingRegistrationScreen> createState() => _BuildingRegistrationScreenState();
}

class _BuildingRegistrationScreenState extends ConsumerState<BuildingRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _memoController = TextEditingController();

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {

    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      // 이미지 선택 실패
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
      String? imageUrl;

      // 이미지가 선택되었으면 S3에 업로드하고 URL 받기
      if (_selectedImage != null) {
        try {
          final imageUploadService = ref.read(imageUploadServiceProvider);
          final fileBytes = await _selectedImage!.readAsBytes();

          imageUrl = await imageUploadService.uploadImage(
            fileBytes: fileBytes,
            fileName: _selectedImage!.path.split('/').last,
            contentType: ImageUploadService.getContentType(_selectedImage!.path),
            folder: 'buildings',
          );
        } catch (e) {
          return;
        }
      }

      // S3 URL을 포함하여 건물 등록 API 호출
      final buildingDataSource = ref.read(buildingRemoteDataSourceProvider);

      final response = await buildingDataSource.createBuilding(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        imageUrl: imageUrl,
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );

      if (mounted) {
        if (response['success'] == true) {
          // 건물 목록 새로고침 트리거
          ref.read(buildingRefreshTriggerProvider.notifier).state++;
          context.pop(true);  // true를 반환하여 목록 새로고침 신호
        }
      }
    } catch (e) {
      // 건물 등록 실패
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
          '건물 등록',
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
              // 건물명 필드
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
                    return '건물명을 입력해주세요';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // 주소 필드
              fieldLabel('주소', context),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        hintText: '주소를 입력해주세요',
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
                          return '주소를 입력해주세요';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),

              const SizedBox(height: 24),

              // 이미지 선택 필드
              fieldLabel('이미지', context),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
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
                              '이미지를 선택해주세요',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),

              // 메모 필드
              fieldLabel('메모', context),
              const SizedBox(height: 8),
              TextFormField(
                controller: _memoController,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: '메모를 입력해주세요',
                  hintStyle: TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Color(0xFFF8F9FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),

              const SizedBox(height: 40),

              // 등록 버튼
              SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  label: _isLoading ? '등록 중...' : '건물 등록',
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
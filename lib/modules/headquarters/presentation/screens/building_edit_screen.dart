import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/modules/headquarters/presentation/providers/headquarters_providers.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BuildingEditScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> building;

  const BuildingEditScreen({
    super.key,
    required this.building,
  });

  @override
  ConsumerState<BuildingEditScreen> createState() => _BuildingEditScreenState();
}

class _BuildingEditScreenState extends ConsumerState<BuildingEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _addressController;
  late final TextEditingController _memoController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.building['name'] ?? '');
    _addressController = TextEditingController(text: widget.building['address'] ?? '');
    _memoController = TextEditingController(text: widget.building['memo'] ?? '');
  }

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
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '이미지 선택 실패',
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
      String? imageUrl;

      // 새로운 이미지가 선택되었으면 S3에 업로드하고 URL 받기
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

      // S3 URL 또는 기존 URL을 포함하여 건물 수정 API 호출
      final buildingDataSource = ref.read(buildingRemoteDataSourceProvider);

      final response = await buildingDataSource.updateBuilding(
        buildingId: widget.building['id'].toString(),
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        imageUrl: imageUrl ?? widget.building['imageUrl'],
        memo: _memoController.text.trim().isEmpty ? null : _memoController.text.trim(),
      );

      if (mounted) {
        if (response['success'] == true) {
          // 건물 목록 새로고침 트리거
          ref.read(buildingRefreshTriggerProvider.notifier).state++;

          // 수정 완료 모달 표시
          await showCustomConfirmationDialog(
            context: context,
            title: '',
            content: const Text(
              '수정이 완료되었습니다.',
              style: TextStyle(
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

          if (mounted) {
            context.pop();
          }
        } else {
          await showErrorAlert(
            context,
            title: '건물 수정 실패',
            message: '건물 정보를 수정하지 못했습니다. 잠시 후 다시 시도해 주세요.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: '건물 수정 실패',
          error: e,
          fallback: '건물 정보를 수정하지 못했습니다. 잠시 후 다시 시도해 주세요.',
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
    final currentImageUrl = widget.building['imageUrl'];

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
          '건물 수정',
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
                      : currentImageUrl != null && currentImageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: currentImageUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) => const Column(
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

              // 수정 버튼
              SizedBox(
                width: double.infinity,
                child: PrimaryActionButton(
                  label: _isLoading ? '수정 중...' : '건물 수정',
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

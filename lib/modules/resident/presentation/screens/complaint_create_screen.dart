import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:building_manage_front/modules/resident/presentation/providers/resident_providers.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
import 'dart:io';

class ComplaintCreateScreen extends ConsumerStatefulWidget {
  final String departmentId;
  final String departmentName;

  const ComplaintCreateScreen({
    super.key,
    required this.departmentId,
    required this.departmentName,
  });

  @override
  ConsumerState<ComplaintCreateScreen> createState() => _ComplaintCreateScreenState();
}

class _ComplaintCreateScreenState extends ConsumerState<ComplaintCreateScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_updateFormState);
    _contentController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    setState(() {
      // 폼 상태 변경시 UI 재빌드
    });
  }

  bool get _isFormValid {
    return _titleController.text.trim().length >= 3 &&
        _contentController.text.trim().length >= 10;
  }

  bool get _hasImage {
    return _selectedImage != null || _uploadedImageUrl != null;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
        _updateFormState();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지를 선택할 수 없습니다: $e')),
        );
      }
    }
  }

  Future<void> _submitComplaint() async {
    if (!_isFormValid) return;

    try {
      String? imageUrl = _uploadedImageUrl;

      // 이미지가 선택되었지만 아직 업로드되지 않았으면 업로드 처리
      if (_selectedImage != null && _uploadedImageUrl == null) {
        setState(() {
          _isUploadingImage = true;
        });

        try {
          final imageUploadService = ref.read(imageUploadServiceProvider);
          final fileBytes = await _selectedImage!.readAsBytes();

          imageUrl = await imageUploadService.uploadImage(
            fileBytes: fileBytes,
            fileName: _selectedImage!.name,
            contentType: 'image/jpeg',
            folder: 'complaints',
          );

          setState(() {
            _uploadedImageUrl = imageUrl;
            _isUploadingImage = false;
          });
        } catch (e) {
          setState(() {
            _isUploadingImage = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 업로드 실패: $e'),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
          return;
        }
      }

      // UseCase를 통한 민원 생성 (비즈니스 로직 포함)
      final createComplaintUseCase = ref.read(createComplaintUseCaseProvider);

      await createComplaintUseCase.execute(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        departmentId: widget.departmentId,
        imageUrl: imageUrl,
      );

      // 등록 완료 화면으로 이동
      if (mounted) {
        context.pushReplacementNamed('complaintComplete');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = '민원 등록 실패';

        // DioException에서 서버 에러 메시지 추출
        if (e.toString().contains('해당 부서는')) {
          errorMessage = '이 부서는 현재 건물에서 이용할 수 없습니다.\n다른 부서를 선택해주세요.';
        } else if (e.toString().contains('message:')) {
          // 다른 서버 에러 메시지가 있으면 추출
          final match = RegExp(r'message: ([^,}]+)').firstMatch(e.toString());
          if (match != null) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    // 업로드 중일 때
    if (_isUploadingImage) {
      return Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: CircularProgressIndicator(
                color: Color(0xFF006FFF),
                strokeWidth: 3,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '이미지 업로드 중...',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFF006FFF),
              ),
            ),
          ],
        ),
      );
    }

    // 업로드된 이미지가 있을 때
    if (_uploadedImageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: _uploadedImageUrl!,
              fit: BoxFit.cover,
              progressIndicatorBuilder: (context, url, downloadProgress) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F8FC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          value: downloadProgress.progress,
                          color: const Color(0xFF006FFF),
                          strokeWidth: 3,
                        ),
                      ),
                    ],
                  ),
                );
              },
              errorWidget: (context, url, error) {
                return Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFFF6B6B),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '이미지 로드 실패',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFFFF6B6B),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          // 삭제 버튼
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                    _uploadedImageUrl = null;
                  });
                  _updateFormState();
                },
              ),
            ),
          ),
        ],
      );
    }

    // 선택된 로컬 이미지가 있을 때 (미업로드 상태)
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_selectedImage!.path),
              fit: BoxFit.cover,
            ),
          ),
          // 삭제 버튼
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                iconSize: 20,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 36,
                  minHeight: 36,
                ),
                onPressed: () {
                  setState(() {
                    _selectedImage = null;
                  });
                  _updateFormState();
                },
              ),
            ),
          ),
        ],
      );
    }

    // 이미지 미선택 상태
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8FC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 48,
            color: Color(0xFFA4ADB2),
          ),
          SizedBox(height: 8),
          Text(
            '사진 첨부',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFFA4ADB2),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF17191A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '민원 등록',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isFormValid ? _submitComplaint : null,
            child: Text(
              '등록',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _isFormValid
                    ? const Color(0xFF006FFF)
                    : const Color(0xFFA4ADB2),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 부서명 표시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE8EEF2), width: 1),
                ),
              ),
              child: Text(
                widget.departmentName,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF17191A),
                ),
              ),
            ),

            // 제목 및 내용 입력
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 + 사진 아이콘
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _titleController,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Color(0xFF17191A),
                          ),
                          decoration: const InputDecoration(
                            hintText: '제목 입력 (최소 3자)',
                            hintStyle: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                              color: Color(0xFFA4ADB2),
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 사진 첨부 아이콘
                      GestureDetector(
                        onTap: _isUploadingImage ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 24,
                            color: _hasImage
                                ? const Color(0xFF006FFF)
                                : const Color(0xFFA4ADB2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: const Color(0xFFE8EEF2),
                  ),
                  const SizedBox(height: 8),
                  // 이미지 미리보기 (내용 필드 위)
                  if (_hasImage)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        height: 160,
                        width: double.infinity,
                        child: _buildImagePreview(),
                      ),
                    ),
                  // 내용 입력
                  TextField(
                    controller: _contentController,
                    maxLines: null,
                    minLines: 5,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                      height: 1.8,
                    ),
                    decoration: const InputDecoration(
                      hintText: '내용을 입력하세요. (최소 10자)',
                      hintStyle: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFFA4ADB2),
                        height: 1.8,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Color(0xFFE8EEF2), width: 1),
          ),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: _isFormValid ? _submitComplaint : null,
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
                '민원등록',
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
      ),
    );
  }
}

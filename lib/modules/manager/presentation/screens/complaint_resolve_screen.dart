import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:building_manage_front/modules/manager/presentation/providers/manager_providers.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
import 'dart:io';

class ComplaintResolveScreen extends ConsumerStatefulWidget {
  final String complaintId;
  final String complaintTitle;
  final Map<String, dynamic> complaintData;

  const ComplaintResolveScreen({
    super.key,
    required this.complaintId,
    required this.complaintTitle,
    required this.complaintData,
  });

  @override
  ConsumerState<ComplaintResolveScreen> createState() => _ComplaintResolveScreenState();
}

class _ComplaintResolveScreenState extends ConsumerState<ComplaintResolveScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  String? _uploadedImageUrl;
  bool _isUploadingImage = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _contentController.addListener(_updateFormState);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _updateFormState() {
    setState(() {
      // 폼 상태 변경시 UI 재빌드
    });
  }

  bool get _isFormValid {
    return _contentController.text.trim().length >= 10;
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

  Future<void> _submitResolve() async {
    if (!_isFormValid) return;

    // 이미지가 선택되었지만 아직 업로드되지 않았으면 먼저 업로드
    if (_selectedImage != null && _uploadedImageUrl == null) {
      await _uploadImageBeforeSubmit();
      // 업로드 실패하면 여기서 반환됨
      if (!mounted) return;
    }

    // 이미지 업로드가 완료되었으면 민원 처리 등록
    await _submitComplaintResolve();
  }

  Future<void> _uploadImageBeforeSubmit() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      final imageUploadService = ref.read(imageUploadServiceProvider);
      final fileBytes = await _selectedImage!.readAsBytes();

      final imageUrl = await imageUploadService.uploadImage(
        fileBytes: fileBytes,
        fileName: _selectedImage!.name,
        contentType: 'image/jpeg',
        folder: 'complaint-results',
      );

      if (mounted) {
        setState(() {
          _uploadedImageUrl = imageUrl;
          _isUploadingImage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('이미지 업로드 실패: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return; // 업로드 실패 시 민원 등록 진행 안함
    }
  }

  Future<void> _submitComplaintResolve() async {
    try {
      setState(() {
        _isSubmitting = true;
      });

      // UseCase를 통한 민원 처리 등록
      final resolveComplaintUseCase = ref.read(resolveComplaintUseCaseProvider);

      await resolveComplaintUseCase.execute(
        complaintId: widget.complaintId,
        content: _contentController.text.trim(),
        imageUrl: _uploadedImageUrl,
      );

      // 처리 완료 화면으로 이동
      if (mounted) {
        context.pushReplacementNamed('complaintResolveComplete');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        String errorMessage = '민원 처리 등록 실패';

        // 에러 메시지 추출
        if (e.toString().contains('message:')) {
          final match = RegExp(r'message: ([^,}]+)').firstMatch(e.toString());
          if (match != null) {
            errorMessage = match.group(1) ?? errorMessage;
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    // 선택된 로컬 이미지가 있을 때 (업로드 전 또는 업로드 중)
    if (_selectedImage != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              children: [
                // 로컬 파일 이미지
                Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
                // 업로드 중 오버레이
                if (_isUploadingImage)
                  Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              color: Color(0xFFFFFFFF),
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
                              color: Color(0xFFFFFFFF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
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
                onPressed: _isUploadingImage || _isSubmitting
                    ? null
                    : () {
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

    // 업로드된 이미지가 있을 때 (로컬 파일 없음)
    if (_uploadedImageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: _uploadedImageUrl!,
              fit: BoxFit.cover,
              placeholder: (context, url) {
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
          '민원 처리 등록',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: (_isFormValid && !_isSubmitting) ? _submitResolve : null,
            child: Text(
              '등록',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: (_isFormValid && !_isSubmitting)
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
            // 민원 정보 표시
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFE8EEF2), width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '처리 대상 민원',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: Color(0xFF757B80),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.complaintTitle,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                  ),
                ],
              ),
            ),

            // 처리 내용 입력
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
                        child: Text(
                          '처리 내용',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Color(0xFF17191A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // 사진 첨부 아이콘
                      GestureDetector(
                        onTap: (_isUploadingImage || _isSubmitting) ? null : _pickImage,
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
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 300,
                          minHeight: 160,
                        ),
                        child: _buildImagePreview(),
                      ),
                    ),
                  // 내용 입력
                  TextField(
                    controller: _contentController,
                    enabled: !_isSubmitting,
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
                      hintText: '처리 내용을 입력하세요. (최소 10자)',
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
              onPressed: (_isFormValid && !_isSubmitting) ? _submitResolve : null,
              style: FilledButton.styleFrom(
                backgroundColor: (_isFormValid && !_isSubmitting)
                    ? const Color(0xFF006FFF)
                    : const Color(0xFFE8EEF2),
                disabledBackgroundColor: const Color(0xFFE8EEF2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _isSubmitting ? '처리 중...' : '처리 등록',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: (_isFormValid && !_isSubmitting)
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

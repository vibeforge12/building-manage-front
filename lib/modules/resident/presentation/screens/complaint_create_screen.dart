import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:building_manage_front/modules/resident/data/datasources/complaint_remote_datasource.dart';
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
      final dataSource = ref.read(complaintRemoteDataSourceProvider);

      // TODO: 이미지 업로드 API가 있다면 먼저 이미지 업로드 후 imageUrl을 받아오기
      // 현재는 imageUrl을 null로 처리

      await dataSource.createComplaint(
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        departmentId: widget.departmentId,
        imageUrl: null, // TODO: 이미지 업로드 후 URL 반환
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
              padding: const EdgeInsets.all(16),
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

            // 이미지 첨부 영역
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 245,
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE8EEF2), width: 1),
                  ),
                ),
                child: _selectedImage == null
                    ? Container(
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
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(_selectedImage!.path),
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      ),
              ),
            ),

            // 제목 및 내용 입력
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
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
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: const Color(0xFFE8EEF2),
                  ),
                  const SizedBox(height: 8),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class NoticeCreateScreen extends ConsumerStatefulWidget {
  final bool isEvent;
  final String? noticeId; // 수정 모드용

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
  bool _isEditing = false; // 수정 모드 여부

  // 이미지 관련 상태
  File? _selectedImageFile;
  String? _existingImageUrl; // 기존 이미지 URL (수정 모드용)
  bool _isUploadingImage = false;
  bool _imageDeleted = false; // 이미지 삭제 여부 추적

  // 모든 필드가 채워졌는지 확인
  // 이벤트: title, content만 필수
  // 공지사항: RESIDENT 또는 BOTH 선택 시 부서 선택 불필요, STAFF만 부서 선택 필수
  bool get _isFormValid {
    if (widget.isEvent) {
      // 이벤트는 제목과 내용만 필수
      return _titleController.text.trim().isNotEmpty &&
          _contentController.text.trim().isNotEmpty;
    } else {
      // 공지사항은 대상 선택에 따라 부서 선택 필수 여부 결정
      final hasDepartment = _selectedTarget != 'STAFF' || _selectedDepartmentId != null;
      return hasDepartment &&
          _titleController.text.trim().isNotEmpty &&
          _contentController.text.trim().isNotEmpty;
    }
  }

  @override
  void initState() {
    super.initState();

    // 텍스트 변경 시 UI 업데이트
    _titleController.addListener(_updateFormState);
    _contentController.addListener(_updateFormState);

    // 비동기 작업 수행
    _initializeAsync();
  }

  Future<void> _initializeAsync() async {
    // 부서 목록 먼저 로드
    await _loadDepartments();

    // 부서 로드 완료 후 UI 업데이트
    if (mounted) {
      setState(() {
        print('✅ 부서 로드 완료: $_departments');
      });
    }

    // 부서 로드 완료 후 수정 모드라면 공지사항 상세 정보 로드
    if (widget.noticeId != null && mounted) {
      print('🔄 공지사항 상세 로드 시작: ${widget.noticeId}');
      await _loadNoticeDetail();

      print('✅ 공지사항 로드 완료: selectedTarget=$_selectedTarget, deptName=$_selectedDepartmentName');

      // 공지사항 로드 완료 후 한 번 더 UI 업데이트
      if (mounted) {
        setState(() {
          // UI 재빌드하여 부서명이 제대로 표시되도록 함
        });
      }
    }
  }

  Future<void> _loadNoticeDetail() async {
    if (widget.noticeId == null) return;

    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);

      // 이벤트/공지사항에 따라 다른 API 호출
      final response = widget.isEvent
          ? await noticeDataSource.getEventDetail(widget.noticeId!)
          : await noticeDataSource.getNoticeDetail(widget.noticeId!);

      print('📋 전체 API 응답: $response');

      // 응답 구조 처리: { success, data: { data: {...} } } 또는 { success, data: {...} }
      final responseData = response['data'];
      final data = responseData is Map && responseData.containsKey('data')
          ? responseData['data']
          : responseData;

      print('📋 파싱된 공지/이벤트 데이터: $data');

      if (mounted) {
        setState(() {
          _isEditing = true; // 수정 모드 활성화
          _titleController.text = data['title'] as String? ?? '';
          _contentController.text = data['content'] as String? ?? '';
          // 기존 이미지 URL 저장
          if (data['imageUrl'] != null) {
            _existingImageUrl = data['imageUrl'] as String;
            print('🖼️ 기존 이미지 URL 설정됨: $_existingImageUrl');
          } else {
            print('⚠️ 이미지 URL이 null입니다');
          }
          // 이벤트가 아닌 경우만 target과 department 로드
          if (!widget.isEvent) {
            _selectedTarget = data['target'] as String? ?? 'BOTH';
            print('🎯 선택된 target: $_selectedTarget');

            // 부서 객체에서 직접 추출 (API 응답에 department 객체가 있음)
            final departmentObj = data['department'];
            print('📦 department 객체: $departmentObj');

            if (departmentObj != null && departmentObj is Map) {
              // department 객체가 있으면 id와 name 추출
              final deptId = departmentObj['id'] as String?;
              final deptName = departmentObj['name'] as String?;

              print('✅ department에서 추출 - ID: $deptId, Name: $deptName');

              if (deptId != null) {
                _selectedDepartmentId = deptId;
                _selectedDepartmentName = deptName ?? '부서 선택';
                print('✅ 부서 설정 완료: $_selectedDepartmentName');
              }
            }
            // departmentId 필드가 있으면 그것도 지원 (호환성)
            else if (data['departmentId'] != null) {
              _selectedDepartmentId = data['departmentId'] as String;
              print('🔄 departmentId 필드 사용: $_selectedDepartmentId');

              // 부서명을 _departments에서 찾기
              if (_departments.isNotEmpty) {
                try {
                  final dept = _departments.firstWhere(
                    (d) => d['id'].toString() == _selectedDepartmentId,
                  );
                  _selectedDepartmentName = dept['name'] as String?? '부서 선택';
                  print('✅ _departments에서 부서명 찾음: $_selectedDepartmentName');
                } catch (e) {
                  print('⚠️ 부서명 찾기 실패: $e');
                  _selectedDepartmentName = '부서 선택';
                }
              }
            } else {
              print('⚠️ department 객체와 departmentId 필드 모두 null');
              _selectedDepartmentName = '부서 선택';
            }

            print('✅ 최종 부서 설정: ID=$_selectedDepartmentId, Name=$_selectedDepartmentName');
          }
        });
      }
    } catch (e) {
      print('${widget.isEvent ? '이벤트' : '공지사항'} 상세 조회 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${widget.isEvent ? '이벤트' : '공지사항'} 조회 실패: $e')),
        );
      }
    }
  }

  void _updateFormState() {
    setState(() {
      // 폼 상태가 변경되면 UI 재빌드
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      print('이미지 선택 실패: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 선택 실패: $e')),
        );
      }
    }
  }

  Widget _buildImagePreview() {
    print('🖼️ 이미지 로딩 - URL: $_existingImageUrl');
    print('🔍 URL 검증: ${(_existingImageUrl?.startsWith('https://') ?? false) ? 'HTTPS ✓' : 'HTTPS ✗'}');
    print('🔍 URL 길이: ${_existingImageUrl?.length}');

    return CachedNetworkImage(
      imageUrl: _existingImageUrl!,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      // 로딩 중 표시
      progressIndicatorBuilder: (context, url, downloadProgress) {
        print('⏳ 이미지 로딩 중: $url - ${downloadProgress.progress}');
        return Container(
          height: 200,
          width: double.infinity,
          color: const Color(0xFFF2F8FC),
          child: Center(
            child: CircularProgressIndicator(
              value: downloadProgress.progress,
              color: const Color(0xFF006FFF),
            ),
          ),
        );
      },
      // 이미지 로드 완료 시
      imageBuilder: (context, imageProvider) {
        print('✅ 이미지 로드 성공');
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
        );
      },
      // 로드 실패 시
      errorWidget: (context, url, error) {
        print('❌ 이미지 로드 실패 - URL: $url');
        print('❌ 에러 상세: $error');
        return Container(
          height: 200,
          width: double.infinity,
          color: const Color(0xFFF2F8FC),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.broken_image,
                  size: 48,
                  color: Color(0xFFE8EEF2),
                ),
                const SizedBox(height: 8),
                Text(
                  '이미지 로드 실패',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
      print('부서 목록 조회 패: $e');
    } finally {
      setState(() {
        _isDepartmentsLoading = false;
      });
    }
  }


  Future<void> _submitNotice() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // STAFF 대상인 경우에만 부서 선택 필수
    if (!widget.isEvent && _selectedTarget == 'STAFF' && _selectedDepartmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('부서를 선택해주세요'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() => _isUploadingImage = true);

      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final title = _titleController.text.trim();
      final content = _contentController.text.trim();

      // 이미지 업로드 처리
      String? imageUrl;

      // 수정 모드에서 이미지가 삭제된 경우
      if (_isEditing && _imageDeleted) {
        imageUrl = null; // 이미지를 명시적으로 삭제
        print('✂️ 이미지 삭제 요청');
      }
      // 새로운 이미지가 선택된 경우
      else if (_selectedImageFile != null) {
        try {
          final imageUploadService = ref.read(imageUploadServiceProvider);
          final imageBytes = await _selectedImageFile!.readAsBytes();
          final fileName = _selectedImageFile!.path.split('/').last;

          imageUrl = await imageUploadService.uploadImage(
            fileBytes: imageBytes,
            fileName: fileName,
            contentType: 'image/jpeg',
            folder: widget.isEvent ? 'events' : 'notices',
          );
          print('📤 이미지 업로드 완료: $imageUrl');
        } catch (e) {
          print('❌ 이미지 업로드 실패: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('이미지 업로드 실패: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isUploadingImage = false);
          return;
        }
      }
      // 그 외: 새 이미지가 없고 기존 이미지도 삭제되지 않음
      // imageUrl은 null 유지 (기존 이미지 유지)

      if (_isEditing && widget.noticeId != null) {
        // 수정 모드: PATCH API 호출
        if (widget.isEvent) {
          // 이벤트 수정 (target, departmentId 제외)
          await noticeDataSource.updateEvent(
            eventId: widget.noticeId!,
            title: title,
            content: content,
            imageUrl: imageUrl,
          );
        } else {
          // 공지사항 수정
          await noticeDataSource.updateNotice(
            noticeId: widget.noticeId!,
            title: title,
            content: content,
            target: _selectedTarget,
            departmentId: _selectedTarget == 'STAFF' ? _selectedDepartmentId : null,
            imageUrl: imageUrl,
          );
        }

        if (mounted) {
          // 수정 완료 모달 표시
          await showCustomConfirmationDialog(
            context: context,
            title: '',
            content: Text(
              '${widget.isEvent ? '이벤트' : '공지사항'}이 수정되었습니다.',
              style: const TextStyle(
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
            // 수정 성공 시 true를 반환하여 부모 화면에서 새로고침하도록 함
            context.pop(true);
          }
        }
      } else {
        // 생성 모드: POST API 호출
        if (widget.isEvent) {
          // 이벤트 생성 (target, departmentId 제외)
          await noticeDataSource.createEvent(
            title: title,
            content: content,
            imageUrl: imageUrl,
          );
        } else {
          // 공지사항 생성
          await noticeDataSource.createNotice(
            title: title,
            content: content,
            target: _selectedTarget,
            departmentId: _selectedTarget == 'STAFF' ? _selectedDepartmentId : null,
            imageUrl: imageUrl,
          );
        }

        if (mounted) {
          // 등록 완료 모달 표시
          await showCustomConfirmationDialog(
            context: context,
            title: '',
            content: Text(
              '${widget.isEvent ? '이벤트' : '공지사항'}이 등록되었습니다.',
              style: const TextStyle(
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
            // 등록 성공 시 true를 반환하여 부모 화면에서 새로고침하도록 함
            context.pop(true);
          }
        }
      }
    } catch (e) {
      print('${widget.isEvent ? '이벤트' : '공지사항'} ${_isEditing ? '수정' : '등록'} 실패: $e');

      // 에러 메시지 안전하게 추출
      String errorMessage = '${_isEditing ? '수정' : '등록'} 실패';
      if (e is DioException && e.response?.data != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic>) {
          final message = data['message'];
          if (message is List && message.isNotEmpty) {
            errorMessage += ': ${message.join(', ')}';
          } else if (message is String) {
            errorMessage += ': $message';
          }
        }
      } else {
        errorMessage += ': $e';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔨 BUILD - isEditing: $_isEditing, noticeId: ${widget.noticeId}');
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
        title: Text(
          _isEditing
              ? (widget.isEvent ? '이벤트 수정' : '공지사항 수정')
              : (widget.isEvent ? '이벤트 등록' : '공지사항 등록'),
          style: const TextStyle(
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 유저 섹션 드롭다운 (공지사항에만 표시, 이벤트는 숨김)
                    if (!widget.isEvent)
                      PopupMenuButton<String>(
                        initialValue: _selectedTarget,
                        offset: const Offset(0, 48),
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                          maxWidth: MediaQuery.of(context).size.width,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'BOTH',
                            child: Text(
                              '전체',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'RESIDENT',
                            child: Text(
                              '유저',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'STAFF',
                            child: Text(
                              '담당자',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          setState(() {
                            _selectedTarget = value;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE8EEF2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getTargetLabel(),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Color(0xFF17191A),
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                size: 24,
                                color: Color(0xFF17191A),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 부서 드롭다운 (공지사항의 STAFF 대상에만 표시, 이벤트는 숨김)
                    if (!widget.isEvent)
                      PopupMenuButton<String>(
                        enabled: !_isDepartmentsLoading && _departments.isNotEmpty && _selectedTarget == 'STAFF',
                        offset: const Offset(0, 48),
                        color: Colors.white,
                        surfaceTintColor: Colors.white,
                        constraints: BoxConstraints(
                          minWidth: MediaQuery.of(context).size.width,
                          maxWidth: MediaQuery.of(context).size.width,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                        itemBuilder: (context) => _departments.map((dept) {
                          return PopupMenuItem(
                            value: dept['id'] as String,
                            child: Text(
                              dept['name'] as String,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          );
                        }).toList(),
                        onSelected: (value) {
                          setState(() {
                            _selectedDepartmentId = value;
                            _selectedDepartmentName = _departments
                                .firstWhere((dept) => dept['id'] == value)['name'] as String;
                          });
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: _selectedTarget == 'RESIDENT'
                                    ? const Color(0xFFE8EEF2)
                                    : const Color(0xFFE8EEF2),
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedTarget == 'STAFF'
                                    ? _selectedDepartmentName
                                    : _selectedTarget == 'RESIDENT'
                                        ? '부서 선택 (유저 대상 시 불필요)'
                                        : '부서 선택 (전체 대상 시 불필요)',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: _selectedTarget == 'STAFF'
                                      ? const Color(0xFF17191A)
                                      : const Color(0xFFA4ADB2),
                                ),
                              ),
                              _isDepartmentsLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 24,
                                      color: _selectedTarget == 'STAFF'
                                          ? const Color(0xFF17191A)
                                          : const Color(0xFFA4ADB2),
                                    ),
                            ],
                          ),
                        ),
                      ),

                    // 제목 및 내용 입력
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 제목 (갤러리 아이콘 포함)
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _titleController,
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
                              ),
                              IconButton(
                                onPressed: _pickImage,
                                icon: const Icon(
                                  Icons.image,
                                  size: 28,
                                  color: Color(0xFF006FFF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Divider(height: 1, color: Color(0xFFE8EEF2)),
                          const SizedBox(height: 16),
                          // 이미지 미리보기 (선택된 이미지 또는 기존 이미지)
                          if (_selectedImageFile != null || _existingImageUrl != null)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '첨부 이미지',
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                    color: Color(0xFF464A4D),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: _selectedImageFile != null
                                          ? Image.file(
                                              _selectedImageFile!,
                                              height: 200,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            )
                                          : _buildImagePreview(),
                                    ),
                                    Positioned(
                                      top: 12,
                                      right: 12,
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedImageFile = null;
                                            _existingImageUrl = null;
                                            // 이미지가 삭제되었음을 표시
                                            if (_isEditing) {
                                              _imageDeleted = true;
                                            }
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(alpha: 0.7),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          padding: const EdgeInsets.all(8),
                                          child: const Icon(
                                            Icons.close,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          // 내용
                          TextFormField(
                            controller: _contentController,
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

            // 등록/수정 버튼
            Container(
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: (_isFormValid && !_isUploadingImage) ? _submitNotice : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: (_isFormValid && !_isUploadingImage)
                        ? const Color(0xFF006FFF)
                        : const Color(0xFFE8EEF2),
                    disabledBackgroundColor: const Color(0xFFE8EEF2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF006FFF),
                            ),
                          ),
                        )
                      : Text(
                          _isEditing ? '수정하기' : '등록하기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: (_isFormValid && !_isUploadingImage)
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
    );
  }

  String _getTargetLabel() {
    switch (_selectedTarget) {
      case 'BOTH':
        return '전체';
      case 'RESIDENT':
        return '유저';
      case 'STAFF':
        return '담당자';
      default:
        return '전체';
    }
  }
}

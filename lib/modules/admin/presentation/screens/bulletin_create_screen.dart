import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/modules/admin/data/datasources/bulletin_remote_datasource.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/bulletin_building_field.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/bulletin_image_strip.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/bulletin_period_field.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/bulletin_push_checkbox.dart';
import 'package:building_manage_front/modules/resident/domain/entities/bulletin.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';

/// 공고문 한 건에 붙일 수 있는 사진 수. 서버 DTO·DB CHECK 와 같은 값이어야 한다.
const int _maxImages = 5;

/// 공고문 등록·수정.
///
/// 등록과 수정을 한 화면으로 둔 이유는 입력 항목이 완전히 같기 때문이다. 화면을 나누면
/// 게시기간·이미지·검증 로직이 두 벌이 되고 언젠가 한쪽만 고쳐진다.
/// 역할별로 나누지 않은 이유도 같다 — 본사에만 건물 선택이 붙을 뿐 나머지가 동일하다.
///
/// [bulletinId] 가 있으면 수정, 없으면 등록이다.
class BulletinCreateScreen extends ConsumerStatefulWidget {
  const BulletinCreateScreen({super.key, this.bulletinId});

  final String? bulletinId;

  bool get isEdit => bulletinId != null;

  @override
  ConsumerState<BulletinCreateScreen> createState() =>
      _BulletinCreateScreenState();
}

class _BulletinCreateScreenState extends ConsumerState<BulletinCreateScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _picker = ImagePicker();

  /// 아직 업로드하지 않은, 기기에서 고른 사진.
  final List<XFile> _pickedImages = [];

  /// 이미 서버에 있는 사진(수정 화면에서 기존 이미지). 표시는 서명 URL 로 한다.
  List<String> _existingImageUrls = [];

  DateTime? _postedFrom;
  DateTime? _postedUntil;
  bool _sendPush = false;

  /// 본사가 고른 건물. 관리자·담당자는 쓰지 않는다.
  List<Map<String, dynamic>> _allBuildings = [];
  final Set<String> _selectedBuildingIds = {};

  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _loadError;

  bool get _isHeadquarters =>
      ref.read(currentUserProvider)?.userType == UserType.headquarters;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      if (_isHeadquarters) await _loadBuildings();
      if (widget.isEdit) await _loadBulletin();
    } catch (e) {
      if (mounted) {
        setState(() =>
            _loadError = userMessageOf(e, fallback: '정보를 불러오지 못했습니다.'));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadBuildings() async {
    final dataSource = ref.read(adminBulletinRemoteDataSourceProvider);
    final response = await dataSource.getTargetBuildings();
    if (response['success'] == true && response['data'] is List) {
      _allBuildings =
          List<Map<String, dynamic>>.from(response['data'] as List);
    }
  }

  Future<void> _loadBulletin() async {
    final dataSource = ref.read(adminBulletinRemoteDataSourceProvider);
    final response = await dataSource.getBulletinDetail(widget.bulletinId!);
    if (response['success'] != true || response['data'] == null) return;

    final bulletin = Bulletin.fromJson(response['data'] as Map<String, dynamic>);
    _titleController.text = bulletin.title;
    _contentController.text = bulletin.content ?? '';
    _existingImageUrls = List<String>.from(bulletin.imageUrls);
    _postedFrom = bulletin.postedFrom;
    _postedUntil = bulletin.postedUntil;
  }

  int get _totalImageCount => _existingImageUrls.length + _pickedImages.length;

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_titleController.text.trim().isEmpty) return false;
    // 본문과 사진 중 최소 하나. 서버도 같은 규칙으로 400 을 주지만,
    // 등록 버튼을 눌러 실패를 겪게 하는 대신 버튼을 비활성화해 미리 알린다.
    if (_contentController.text.trim().isEmpty && _totalImageCount == 0) {
      return false;
    }
    if (_isHeadquarters && _selectedBuildingIds.isEmpty && !widget.isEdit) {
      return false;
    }
    return true;
  }

  Future<void> _pickImages() async {
    final remaining = _maxImages - _totalImageCount;
    if (remaining <= 0) {
      await showErrorAlert(
        context,
        title: '사진을 더 넣을 수 없습니다',
        error: null,
        fallback: '사진은 최대 $_maxImages장까지 첨부할 수 있습니다.',
      );
      return;
    }

    try {
      final images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (images.isEmpty) return;

      // 남은 자리를 넘겨 고른 경우, 실패시키지 않고 앞에서부터 채운다.
      // 여기서 오류를 내면 사용자는 몇 장을 다시 골라야 하는지 알 수 없다.
      final accepted = images.take(remaining).toList();
      setState(() => _pickedImages.addAll(accepted));

      if (images.length > accepted.length && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '사진은 최대 $_maxImages장까지 첨부됩니다. '
              '${accepted.length}장만 추가했습니다.',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '사진 선택 실패',
        error: e,
        fallback: '사진을 불러오지 못했습니다. 다시 시도해 주세요.',
      );
    }
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    if (_postedFrom != null &&
        _postedUntil != null &&
        _postedFrom!.isAfter(_postedUntil!)) {
      await showErrorAlert(
        context,
        title: '게시 기간을 확인해주세요',
        error: null,
        fallback: '게시 종료일이 시작일보다 빠를 수 없습니다.',
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      // 새로 고른 사진을 먼저 S3 에 올리고, 그 키를 본문과 함께 보낸다.
      final uploadedUrls = await _uploadPickedImages();
      final imageUrls = [..._existingImageUrls, ...uploadedUrls];

      final dataSource = ref.read(adminBulletinRemoteDataSourceProvider);
      final content = _contentController.text.trim();

      if (widget.isEdit) {
        await dataSource.updateBulletin(
          bulletinId: widget.bulletinId!,
          title: _titleController.text.trim(),
          content: content,
          imageUrls: imageUrls,
          // 날짜를 지운 경우 null 을 명시적으로 보내야 "제한 없음" 으로 돌아간다.
          clearPostedFrom: _postedFrom == null,
          postedFrom: _postedFrom?.toIso8601String(),
          clearPostedUntil: _postedUntil == null,
          postedUntil: _postedUntil?.toIso8601String(),
        );
      } else {
        await dataSource.createBulletin(
          title: _titleController.text.trim(),
          content: content.isEmpty ? null : content,
          imageUrls: imageUrls,
          buildingIds:
              _isHeadquarters ? _selectedBuildingIds.toList() : null,
          postedFrom: _postedFrom?.toIso8601String(),
          postedUntil: _postedUntil?.toIso8601String(),
          sendPush: _sendPush,
        );
      }

      if (mounted) context.pop(true);
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: widget.isEdit ? '수정 실패' : '등록 실패',
        error: e,
        fallback: '처리하지 못했습니다. 잠시 후 다시 시도해 주세요.',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<List<String>> _uploadPickedImages() async {
    if (_pickedImages.isEmpty) return const [];

    final service = ref.read(imageUploadServiceProvider);
    final files = <Map<String, dynamic>>[];
    for (final image in _pickedImages) {
      files.add({
        'bytes': await image.readAsBytes(),
        'fileName': image.name,
        'contentType': 'image/jpeg',
      });
    }
    return service.uploadMultipleImages(files: files, folder: 'bulletins');
  }


  @override
  Widget build(BuildContext context) {
    final buildingName = ref.watch(currentUserProvider)?.buildingName;
    final actionLabel = widget.isEdit ? '공고문 수정' : '공고문 등록';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        // 공지 등록 화면과 같은 골격: 제목은 건물명, 무엇을 쓰는 중인지는 아랫줄.
        // 본사는 소속 건물이 없어 buildingName 이 비는데, 그때는 폼 안에서 건물을
        // 직접 고르므로 상단에 건물명을 띄울 것이 없다. 그래서 동작 이름으로 돌아간다.
        title: Text(
          buildingName ?? actionLabel,
          // 건물명이 길면 두 줄이 되어 AppBar 높이가 늘어난다. 한 줄로 자른다.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(buildingName == null ? 1 : 55),
          child: Column(
            children: [
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              if (buildingName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  height: 60,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
                      ),
                    )
                  : _loadError != null
                      ? Center(
                          child: Text(
                            _loadError!,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 14,
                              color: Color(0xFF757B80),
                            ),
                          ),
                        )
                      : _buildForm(),
            ),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 선택 컨트롤은 위에 모은다. 공지 등록도 대상·부서 드롭다운이 본문 위에 있고,
          // 글을 쓰기 전에 "어디에, 언제까지" 를 먼저 정하는 순서가 자연스럽다.
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 본사만 건물을 고른다. 수정에서는 건물을 바꿀 수 없으므로 등록에서만 보인다.
                if (_isHeadquarters && !widget.isEdit) ...[
                  BulletinBuildingField(
                    buildings: _allBuildings,
                    selectedIds: _selectedBuildingIds,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                ],
                BulletinPeriodField(
                  postedFrom: _postedFrom,
                  postedUntil: _postedUntil,
                  onChanged: (from, until) => setState(() {
                    _postedFrom = from;
                    _postedUntil = until;
                  }),
                ),
                if (!widget.isEdit) ...[
                  const SizedBox(height: 8),
                  BulletinPushCheckbox(
                    value: _sendPush,
                    onChanged: (value) => setState(() => _sendPush = value),
                  ),
                ],
              ],
            ),
          ),

          // 제목 · 사진 · 내용은 공지/민원 등록과 같은 문서형으로 묶는다.
          // 라벨을 따로 달지 않는 것도 그 화면들과 같다 — 힌트 문구가 라벨 역할을 한다.
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _titleController,
                        maxLength: 200,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: '제목 입력란',
                          hintStyle: _titleHintStyle,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          counterText: '',
                        ),
                        style: _titleTextStyle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // 사진 첨부는 민원 등록과 같은 자리(제목 오른쪽)에 같은 아이콘으로 둔다.
                    GestureDetector(
                      onTap: _totalImageCount >= _maxImages ? null : _pickImages,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 24,
                          color: _totalImageCount > 0
                              ? const Color(0xFF006FFF)
                              : const Color(0xFFA4ADB2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFFE8EEF2)),
                const SizedBox(height: 8),

                // 붙인 사진은 내용 위에 미리보기로 놓는다(민원 등록과 같은 순서).
                if (_totalImageCount > 0) ...[
                  BulletinImageStrip(
                    existingUrls: _existingImageUrls,
                    pickedImages: _pickedImages,
                    maxImages: _maxImages,
                    onRemoveExisting: (i) =>
                        setState(() => _existingImageUrls.removeAt(i)),
                    onRemovePicked: (i) =>
                        setState(() => _pickedImages.removeAt(i)),
                  ),
                  const SizedBox(height: 16),
                ],

                TextField(
                  controller: _contentController,
                  maxLines: 10,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    hintText: '내용을 입력하세요. 사진만 올릴 경우 비워두어도 됩니다.',
                    hintStyle: _contentHintStyle,
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: _contentTextStyle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 제목 — 공지·민원 등록과 같은 크기·굵기.
  static const _titleTextStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: Color(0xFF17191A),
  );

  static const _titleHintStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w700,
    fontSize: 20,
    color: Color(0xFFA4ADB2),
  );

  /// 본문 — 공지 등록과 같은 크기·행간.
  static const _contentTextStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: Color(0xFF17191A),
    height: 1.8,
  );

  static const _contentHintStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: Color(0xFFA4ADB2),
    height: 1.8,
  );

  Widget _buildSubmitBar() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8EEF2), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: _canSubmit ? _submit : null,
          style: FilledButton.styleFrom(
            backgroundColor: _canSubmit
                ? const Color(0xFF006FFF)
                : const Color(0xFFE8EEF2),
            disabledBackgroundColor: const Color(0xFFE8EEF2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  widget.isEdit ? '수정하기' : '등록하기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _canSubmit ? Colors.white : const Color(0xFFA4ADB2),
                  ),
                ),
        ),
      ),
    );
  }
}

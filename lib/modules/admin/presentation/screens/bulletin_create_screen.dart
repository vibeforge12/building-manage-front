import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/modules/admin/data/datasources/bulletin_remote_datasource.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/common/services/image_upload_service.dart';
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

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = (isStart ? _postedFrom : _postedUntil) ?? now;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      locale: const Locale('ko', 'KR'),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _postedFrom = DateTime(picked.year, picked.month, picked.day);
      } else {
        // 종료일은 그날 끝까지 게시되어야 한다. 자정으로 두면 그날 하루가 통째로 빠진다.
        _postedUntil =
            DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
      }
    });
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

  String _formatDate(DateTime date) => DateFormat('yyyy.MM.dd').format(date);

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
                  _buildBuildingSelector(),
                  const SizedBox(height: 8),
                ],
                _buildPeriodSection(),
                if (!widget.isEdit) ...[
                  const SizedBox(height: 8),
                  _buildPushSection(),
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
                  _buildImageSection(),
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

  /// 선택 컨트롤 한 칸. 공지 등록의 드롭다운과 같은 생김새로 맞춘다.
  Widget _selectBox({required Widget child, VoidCallback? onTap}) {
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8FC),
        border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
    return onTap == null
        ? box
        : GestureDetector(onTap: onTap, child: box);
  }

  static const _boxTextStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: Color(0xFF17191A),
  );

  static const _boxHintStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: Color(0xFF757B80),
  );

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

  /// 건물 선택. 폼 안에 체크박스를 늘어놓지 않고 요약 한 줄 + 바텀시트로 둔다.
  /// 본사가 건물을 수십 개 가질 수 있어, 체크박스를 깔면 아래 입력란이 화면 밖으로 밀린다.
  Widget _buildBuildingSelector() {
    final selectedNames = _allBuildings
        .where((b) => _selectedBuildingIds.contains(b['id']))
        .map((b) => b['name']?.toString() ?? '')
        .toList();

    final summary = switch (selectedNames.length) {
      0 => '게시할 건물 선택',
      1 => selectedNames.first,
      _ => '${selectedNames.first} 외 ${selectedNames.length - 1}곳',
    };

    return _selectBox(
      onTap: _openBuildingPicker,
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
              style: selectedNames.isEmpty ? _boxHintStyle : _boxTextStyle,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down, size: 24, color: Color(0xFF757B80)),
        ],
      ),
    );
  }


  Future<void> _openBuildingPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final allSelected =
              _allBuildings.isNotEmpty &&
                  _selectedBuildingIds.length == _allBuildings.length;

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '게시 건물 선택',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        // 본사의 실제 용도가 "전 건물 안내" 라 전체 선택이 사실상 필수다.
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              setState(() {
                                if (allSelected) {
                                  _selectedBuildingIds.clear();
                                } else {
                                  _selectedBuildingIds
                                    ..clear()
                                    ..addAll(_allBuildings
                                        .map((b) => b['id'].toString()));
                                }
                              });
                            });
                          },
                          child: Text(
                            allSelected ? '전체 해제' : '전체 선택',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF006FFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EEF2)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _allBuildings.length,
                      itemBuilder: (context, index) {
                        final building = _allBuildings[index];
                        final id = building['id'].toString();
                        final checked = _selectedBuildingIds.contains(id);
                        return CheckboxListTile(
                          value: checked,
                          activeColor: const Color(0xFF006FFF),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            building['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 15,
                              color: Color(0xFF17191A),
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              setState(() {
                                if (value == true) {
                                  _selectedBuildingIds.add(id);
                                } else {
                                  _selectedBuildingIds.remove(id);
                                }
                              });
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006FFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${_selectedBuildingIds.length}곳 선택 완료',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// 붙인 사진 미리보기. 첨부 버튼은 제목 오른쪽에 따로 있으므로 여기엔 라벨을 두지 않는다.
  /// (민원 등록도 같은 구조다 — 아이콘으로 붙이고, 미리보기는 본문 위에 나온다)
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '사진 $_totalImageCount / $_maxImages',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: Color(0xFF757B80),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < _existingImageUrls.length; i++)
                _thumb(
                  child: CachedNetworkImage(
                    imageUrl: _existingImageUrls[i],
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF757B80)),
                  ),
                  onRemove: () =>
                      setState(() => _existingImageUrls.removeAt(i)),
                ),
              for (int i = 0; i < _pickedImages.length; i++)
                _thumb(
                  child: Image.network(
                    _pickedImages[i].path,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF2F8FC),
                      child: const Icon(Icons.image_outlined,
                          color: Color(0xFF757B80)),
                    ),
                  ),
                  onRemove: () => setState(() => _pickedImages.removeAt(i)),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _thumb({required Widget child, required VoidCallback onRemove}) {
    return Container(
      width: 96,
      height: 96,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 게시 기간. 건물 선택과 같은 박스 하나로 두고, 실제 선택은 시트에서 한다.
  ///
  /// 칩과 날짜 입력줄을 폼에 그대로 펼치면 상단 선택 영역에서 이것만 모양이 달라진다.
  /// 이 저장소의 상단 선택 컨트롤은 전부 "채운 박스를 눌러 고르는" 형태다.
  Widget _buildPeriodSection() {
    final summary = switch ((_postedFrom, _postedUntil)) {
      (null, null) => '무기한 게시',
      (final from?, null) => '${_formatDate(from)}부터 무기한',
      (null, final until?) => '${_formatDate(until)}까지 게시',
      (final from?, final until?) =>
        '${_formatDate(from)} ~ ${_formatDate(until)}',
    };
    final isDefault = _postedFrom == null && _postedUntil == null;

    return _selectBox(
      onTap: _openPeriodPicker,
      child: Row(
        children: [
          Expanded(
            child: Text(summary,
                style: isDefault ? _boxHintStyle : _boxTextStyle),
          ),
          const Icon(Icons.keyboard_arrow_down,
              size: 24, color: Color(0xFF757B80)),
        ],
      ),
    );
  }

  Future<void> _openPeriodPicker() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '게시 기간',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8EEF2)),
              _periodOption(
                label: '무기한 게시',
                description: '직접 내릴 때까지 계속 보입니다.',
                selected: _postedFrom == null && _postedUntil == null,
                onTap: () {
                  setSheetState(() {
                    setState(() {
                      _postedFrom = null;
                      _postedUntil = null;
                    });
                  });
                },
              ),
              _periodOption(
                label: _postedUntil == null
                    ? '종료일 지정'
                    : '${_formatDate(_postedUntil!)}까지',
                description: '기간이 지나면 입주민 화면에서 자동으로 사라집니다.',
                selected: _postedUntil != null,
                onTap: () async {
                  await _pickDate(isStart: false);
                  setSheetState(() {});
                },
              ),
              _periodOption(
                label: _postedFrom == null
                    ? '시작일 지정 (예약 게시)'
                    : '${_formatDate(_postedFrom!)}부터',
                description: '지정한 날짜가 되어야 입주민에게 보입니다.',
                selected: _postedFrom != null,
                onTap: () async {
                  await _pickDate(isStart: true);
                  setSheetState(() {});
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) setState(() {});
  }

  Widget _periodOption({
    required String label,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: selected
                          ? const Color(0xFF006FFF)
                          : const Color(0xFF17191A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFF757B80),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: Color(0xFF006FFF)),
          ],
        ),
      ),
    );
  }


  Widget _buildPushSection() {
    // 박스 전체가 하나의 버튼이다. 체크박스만 누를 수 있게 두면 옆의 설명 글을 눌러도
    // 아무 일이 없어, 체크박스 자체를 정확히 겨눠야 한다.
    // 위의 건물·게시기간 박스도 박스 전체를 누르므로 조작 방식이 같아진다.
    //
    // 체크박스는 자기 탭을 스스로 처리하므로(부모로 전달되지 않는다) 두 번 토글되지 않는다.
    return InkWell(
      onTap: () => setState(() => _sendPush = !_sendPush),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FC),
          border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: _sendPush,
              activeColor: const Color(0xFF006FFF),
              onChanged: (value) => setState(() => _sendPush = value ?? false),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '입주민에게 알림 보내기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF17191A),
                    ),
                  ),
                  SizedBox(height: 2),
                  // 기본이 꺼짐인 이유를 등록자에게 알려준다. 이유를 모르면 매번 켜게 되고,
                  // 그러면 입주민이 앱 알림 자체를 꺼버려 정작 급한 공지가 닿지 않는다.
                  Text(
                    '공고문마다 알림을 보내면 입주민이 알림을 꺼버립니다. 긴급할 때만 사용해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFF757B80),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

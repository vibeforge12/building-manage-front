import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'dart:typed_data';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/bulletin_image_strip.dart';
import 'package:building_manage_front/modules/admin/presentation/widgets/push_opt_in_checkbox.dart';
import '../../domain/usecases/life_service_use_cases.dart';
import '../widgets/life_service_style.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import '../providers/life_service_providers.dart';

class LifeServiceFormScreen extends ConsumerStatefulWidget {
  const LifeServiceFormScreen({super.key, this.lifeServiceId});
  final String? lifeServiceId;
  bool get editing => lifeServiceId != null;
  @override
  ConsumerState<LifeServiceFormScreen> createState() =>
      _LifeServiceFormScreenState();
}

class _LifeServiceFormScreenState extends ConsumerState<LifeServiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _capacity = TextEditingController();
  late DateTime _applicationStart;
  late DateTime _applicationEnd;
  late DateTime _serviceStart;
  late DateTime _serviceEnd;
  bool _loading = false;
  bool _submitting = false;
  bool _sendPush = true;
  String? _loadError;
  final List<String> _imageKeys = [];
  final List<String> _imageUrls = [];
  final List<XFile> _pickedImages = [];
  final Map<String, Uint8List> _pickedBytes = {};
  final Map<String, String> _uploadedKeys = {};
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _applicationStart = now;
    _applicationEnd = now.add(const Duration(days: 7));
    _serviceStart = now.add(const Duration(days: 8));
    _serviceEnd = now.add(const Duration(days: 8, hours: 2));
    if (widget.editing) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _location.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final service = await ref
          .read(lifeServiceUseCasesProvider)
          .detail(widget.lifeServiceId!);
      if (!mounted) return;
      _title.text = service.title;
      _description.text = service.description;
      _location.text = service.location ?? '';
      _capacity.text = service.capacity?.toString() ?? '';
      _applicationStart = service.applicationStartAt;
      _applicationEnd = service.applicationEndAt;
      _serviceStart = service.serviceStartAt;
      _serviceEnd = service.serviceEndAt;
      _imageKeys.addAll(service.imageKeys);
      _imageUrls.addAll(service.imageUrls);
    } catch (e) {
      _loadError = userMessageOf(e, fallback: '신청 정보를 불러오지 못했습니다.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickImages() async {
    if (_picking || _submitting) return;
    setState(() => _picking = true);
    try {
      final available =
          LifeServiceUseCases.maxImages -
          _imageKeys.length -
          _pickedImages.length;
      if (available <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진은 최대 5장까지 첨부할 수 있습니다.')),
        );
        return;
      }
      final picked = await ref
          .read(lifeServiceImagePickerProvider)
          .pickMultiImage(
            // Android의 임시 리사이즈 파일 대신 선택한 원본을 즉시 확보한다.
            maxWidth: defaultTargetPlatform == TargetPlatform.iOS ? 1920 : null,
            maxHeight: defaultTargetPlatform == TargetPlatform.iOS
                ? 1920
                : null,
            imageQuality: defaultTargetPlatform == TargetPlatform.iOS
                ? 85
                : null,
            requestFullMetadata: false,
          );
      if (!mounted) return;
      final accepted = <XFile>[];
      final bytesByPath = <String, Uint8List>{};
      for (final image in picked.take(available)) {
        if (_pickedImages.any((item) => item.path == image.path) ||
            bytesByPath.containsKey(image.path)) {
          continue;
        }
        if (await image.length() > LifeServiceUseCases.maxImageBytes) {
          throw const ApiException(
            message: '사진 한 장은 10MB 이하로 첨부해 주세요.',
            errorCode: 'INVALID_IMAGE_SIZE',
          );
        }
        final bytes = await image.readAsBytes();
        if (bytes.isEmpty || bytes.length > LifeServiceUseCases.maxImageBytes) {
          throw const ApiException(
            message: '사진 한 장은 10MB 이하로 첨부해 주세요.',
            errorCode: 'INVALID_IMAGE_SIZE',
          );
        }
        bytesByPath[image.path] = bytes;
        accepted.add(image);
      }
      if (!mounted) return;
      setState(() {
        _pickedImages.addAll(accepted);
        _pickedBytes.addAll(bytesByPath);
      });
      if (picked.length > available) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('사진은 최대 5장까지 첨부할 수 있습니다.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      await showErrorAlert(
        context,
        title: '사진 첨부 실패',
        error: e is ApiException ? e : null,
        fallback: '사진을 선택하지 못했습니다. 사진 권한과 용량(한 장당 10MB)을 확인해 주세요.',
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _submit() async {
    if (_loading ||
        _loadError != null ||
        _picking ||
        _submitting ||
        !_formKey.currentState!.validate()) {
      return;
    }
    if (_applicationStart.isAfter(_applicationEnd) ||
        _serviceStart.isAfter(_serviceEnd) ||
        _applicationEnd.isAfter(_serviceStart)) {
      await showErrorAlert(
        context,
        title: '기간을 확인해 주세요',
        error: null,
        fallback: '신청 시작·마감과 서비스 진행 순서가 올바르지 않습니다.',
      );
      return;
    }
    setState(() => _submitting = true);
    final data = <String, dynamic>{
      'title': _title.text.trim(),
      'description': _description.text.trim(),
      'applicationStartAt': _applicationStart.toIso8601String(),
      'applicationEndAt': _applicationEnd.toIso8601String(),
      'serviceStartAt': _serviceStart.toIso8601String(),
      'serviceEndAt': _serviceEnd.toIso8601String(),
      'location': _location.text.trim(),
      'capacity': int.tryParse(_capacity.text.trim()),
      if (!widget.editing) 'sendPush': _sendPush,
    };
    try {
      final useCases = ref.read(lifeServiceUseCasesProvider);
      final keys = [..._imageKeys];
      for (final image in _pickedImages) {
        final cached = _uploadedKeys[image.path];
        final key =
            cached ??
            await useCases.uploadImage(_pickedBytes[image.path]!, image.name);
        _uploadedKeys[image.path] = key;
        keys.add(key);
      }
      data['imageKeys'] = keys;
      if (widget.editing) {
        await useCases.update(widget.lifeServiceId!, data);
      } else {
        await useCases.create(data);
      }
      if (mounted) context.pop(true);
    } catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: widget.editing ? '수정 실패' : '등록 실패',
          error: e is ApiException ? e : null,
          fallback: '신청 항목을 저장하지 못했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => LifeServiceStyle(
    child: Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF17191A),
        centerTitle: true,
        title: Text(
          ref.watch(currentUserProvider)?.buildingName ??
              (widget.editing ? '신청 항목 수정' : '새 신청 항목'),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            height: 56,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE8EEF2))),
            ),
            child: Text(
              widget.editing ? '신청 항목 수정' : '새 신청 항목',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(child: Text(_loadError!))
          : Form(
              key: _formKey,
              child: AbsorbPointer(
                absorbing: _submitting,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _title,
                            maxLength: 200,
                            decoration: const InputDecoration(
                              hintText: '서비스 이름을 입력해 주세요',
                              counterText: '',
                              filled: false,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '서비스 이름을 입력해 주세요.'
                                : null,
                          ),
                        ),
                        IconButton(
                          onPressed: _picking ? null : _pickImages,
                          icon: const Icon(
                            Icons.add_photo_alternate_outlined,
                            color: Color(0xFF757B80),
                          ),
                          tooltip: '사진 첨부 (최대 5장)',
                        ),
                      ],
                    ),
                    const Divider(color: Color(0xFFE8EEF2), height: 24),
                    if (_imageUrls.isNotEmpty || _pickedImages.isNotEmpty) ...[
                      BulletinImageStrip(
                        existingUrls: _imageUrls,
                        pickedImages: _pickedImages,
                        pickedBytes: _pickedBytes,
                        maxImages: LifeServiceUseCases.maxImages,
                        onRemoveExisting: (index) => setState(() {
                          _imageKeys.removeAt(index);
                          _imageUrls.removeAt(index);
                        }),
                        onRemovePicked: (index) => setState(() {
                          final image = _pickedImages.removeAt(index);
                          _pickedBytes.remove(image.path);
                          _uploadedKeys.remove(image.path);
                        }),
                        readOnly: _submitting,
                      ),
                      const SizedBox(height: 20),
                    ],
                    TextFormField(
                      controller: _description,
                      minLines: 4,
                      maxLines: 8,
                      maxLength: 5000,
                      decoration: const InputDecoration(
                        hintText: '안내 내용을 입력해 주세요.',
                        counterText: '',
                        filled: false,
                        contentPadding: EdgeInsets.zero,
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        height: 1.8,
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? '안내 내용을 입력해 주세요.'
                          : null,
                    ),
                    const SizedBox(height: 22),
                    _heading('신청 기간'),
                    _DateField(
                      label: '신청 시작',
                      value: _applicationStart,
                      onTap: () async {
                        final v = await _pickDateTime(_applicationStart);
                        if (v != null) setState(() => _applicationStart = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    _DateField(
                      label: '신청 마감',
                      value: _applicationEnd,
                      onTap: () async {
                        final v = await _pickDateTime(_applicationEnd);
                        if (v != null) setState(() => _applicationEnd = v);
                      },
                    ),
                    const SizedBox(height: 22),
                    _heading('진행 정보'),
                    _DateField(
                      label: '서비스 시작',
                      value: _serviceStart,
                      onTap: () async {
                        final v = await _pickDateTime(_serviceStart);
                        if (v != null) setState(() => _serviceStart = v);
                      },
                    ),
                    const SizedBox(height: 10),
                    _DateField(
                      label: '서비스 종료',
                      value: _serviceEnd,
                      onTap: () async {
                        final v = await _pickDateTime(_serviceEnd);
                        if (v != null) setState(() => _serviceEnd = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _location,
                      decoration: const InputDecoration(labelText: '장소 (선택)'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _capacity,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '모집 인원 (비우면 제한 없음)',
                        suffixText: '명',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v);
                        return n == null || n < 1 || n > 10000
                            ? '1~10,000명 사이로 입력해 주세요.'
                            : null;
                      },
                    ),
                    if (!widget.editing) ...[
                      const SizedBox(height: 12),
                      PushOptInCheckbox(
                        helperText: '이 서비스를 등록하면 해당 건물 입주민에게 알려요.',
                        value: _sendPush,
                        onChanged: (value) => setState(() => _sendPush = value),
                      ),
                    ],
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: FilledButton(
            onPressed: _submitting || _loading || _loadError != null || _picking
                ? null
                : _submit,
            child: Text(
              _submitting
                  ? '저장 중...'
                  : widget.editing
                  ? '수정 완료'
                  : '신청 열기',
            ),
          ),
        ),
      ),
    ),
  );

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF464A4D),
      ),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });
  final String label;
  final DateTime value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(DateFormat('yyyy.MM.dd HH:mm').format(value)),
    ),
  );
}

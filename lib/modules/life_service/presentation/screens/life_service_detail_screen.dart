import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:building_manage_front/shared/widgets/full_screen_image_viewer.dart';
import '../widgets/life_service_style.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/shared/widgets/refreshable_content.dart';
import '../../domain/entities/life_service.dart';
import '../providers/life_service_providers.dart';

class LifeServiceDetailScreen extends ConsumerStatefulWidget {
  const LifeServiceDetailScreen({super.key, required this.lifeServiceId});
  final String lifeServiceId;
  @override
  ConsumerState<LifeServiceDetailScreen> createState() =>
      _LifeServiceDetailScreenState();
}

class _LifeServiceDetailScreenState
    extends ConsumerState<LifeServiceDetailScreen> {
  bool _loading = true;
  bool _submitting = false;
  int _loadRequest = 0;
  String? _error;
  LifeService? _service;
  bool get _resident =>
      ref.read(currentUserProvider)?.userType == UserType.user;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = await ref
          .read(lifeServiceUseCasesProvider)
          .detail(widget.lifeServiceId);
      if (mounted && request == _loadRequest) {
        setState(() => _service = service);
      }
    } catch (e) {
      if (mounted && request == _loadRequest) {
        setState(
          () => _error = userMessageOf(e, fallback: '신청 서비스를 불러오지 못했습니다.'),
        );
      }
    } finally {
      if (mounted && request == _loadRequest) setState(() => _loading = false);
    }
  }

  Future<void> _apply() async {
    setState(() => _submitting = true);
    try {
      await ref.read(lifeServiceUseCasesProvider).apply(widget.lifeServiceId);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('서비스 신청이 완료되었습니다.')));
      await _load();
    } catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: '신청 실패',
          error: e,
          fallback: '신청하지 못했습니다. 다시 시도해 주세요.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _cancel() async {
    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '신청을 취소할까요?',
      content: const Text('취소 후 신청 기간 안에는 다시 신청할 수 있습니다.'),
      confirmText: '취소하기',
      cancelText: '아니요',
      isDestructive: true,
    );
    if (confirmed != true || !mounted) return;
    setState(() => _submitting = true);
    try {
      await ref.read(lifeServiceUseCasesProvider).cancel(widget.lifeServiceId);
      if (mounted) {
        await _load();
      }
    } catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: '취소 실패',
          error: e,
          fallback: '신청을 취소하지 못했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _close() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final confirmed = await showCustomConfirmationDialog(
        context: context,
        title: '신청을 마감할까요?',
        content: const Text('마감하면 입주민이 더 이상 신청하거나 취소할 수 없습니다.'),
        confirmText: '마감',
        cancelText: '아니요',
        isDestructive: true,
      );
      if (confirmed != true || !mounted) return;
      await ref.read(lifeServiceUseCasesProvider).close(widget.lifeServiceId);
      if (mounted) {
        await _load();
      }
    } catch (e) {
      if (mounted) {
        await showErrorAlert(
          context,
          title: '마감 실패',
          error: e,
          fallback: '신청을 마감하지 못했습니다.',
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = _service;
    return LifeServiceStyle(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF17191A),
          centerTitle: true,
          title: Text(
            _resident ? '서비스 상세' : '신청 항목 상세',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
        ),
        body: RefreshableContent(
          onRefresh: _load,
          isLoading: _loading && service == null,
          error: _error,
          isEmpty: service == null,
          emptyMessage: '서비스를 찾을 수 없습니다.',
          child: service == null
              ? const SizedBox.shrink()
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.title,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusChip(service: service),
                      ],
                    ),
                    const Divider(color: Color(0xFFE8EEF2), height: 40),
                    _Section(
                      title: '일정',
                      child: Column(
                        children: [
                          _InfoRow(
                            label: '서비스',
                            value:
                                '${_format(service.serviceStartAt)} ~\n${_format(service.serviceEndAt)}',
                          ),
                          _InfoRow(
                            label: '신청',
                            value:
                                '${_format(service.applicationStartAt)} ~\n${_format(service.applicationEndAt)}',
                          ),
                          if (service.location?.isNotEmpty == true)
                            _InfoRow(label: '장소', value: service.location!),
                          _InfoRow(
                            label: '신청 인원',
                            value: service.capacity == null
                                ? '${service.applicantCount}명 / 제한 없음'
                                : '${service.applicantCount}명 / ${service.capacity}명',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (service.imageUrls.isNotEmpty) ...[
                      for (final url in service.imageUrls)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Semantics(
                            button: true,
                            label: '서비스 사진 확대',
                            child: InkWell(
                              onTap: () =>
                                  FullScreenImageViewer.show(context, url),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: url,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 240,
                                  placeholder: (_, __) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  errorWidget: (_, __, ___) => const SizedBox(
                                    height: 120,
                                    child: Center(
                                      child: Text(
                                        '사진을 불러오지 못했습니다. 당겨서 새로고침해 주세요.',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                    _Section(
                      title: '안내',
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          service.description,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            height: 1.8,
                          ),
                        ),
                      ),
                    ),
                    if (!_resident) ...[
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => context.pushNamed(
                          'lifeServiceApplicants',
                          pathParameters: {'lifeServiceId': service.id},
                        ),
                        child: Text('신청자 명단 ${service.applicantCount}명'),
                      ),
                    ],
                  ],
                ),
        ),
        bottomNavigationBar: service == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 16,
                  ),
                  child: _resident
                      ? _residentActions(service)
                      : _operatorActions(service),
                ),
              ),
      ),
    );
  }

  Widget _residentActions(LifeService service) {
    if (service.applicationStatus == LifeServiceApplicationStatus.applied) {
      return OutlinedButton(
        onPressed:
            service.canCancel && !_submitting && !_loading && _error == null
            ? _cancel
            : null,
        child: Text(service.canCancel ? '신청 취소' : '신청 완료'),
      );
    }
    return FilledButton(
      onPressed: service.canApply && !_submitting && !_loading && _error == null
          ? _apply
          : null,
      child: Text(
        _submitting
            ? '처리 중...'
            : service.canApply
            ? '신청하기'
            : '신청할 수 없습니다',
      ),
    );
  }

  Widget _operatorActions(LifeService service) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed:
              !_loading &&
                  !_submitting &&
                  _error == null &&
                  service.canManage &&
                  service.status != LifeServiceDisplayStatus.completed
              ? () async {
                  final changed = await context.pushNamed<bool>(
                    'lifeServiceEdit',
                    pathParameters: {'lifeServiceId': service.id},
                  );
                  if (changed == true && mounted) _load();
                }
              : null,
          child: const Text('수정'),
        ),
      ),
      const SizedBox(width: 8),
      Expanded(
        child: FilledButton(
          onPressed:
              !_loading &&
                  !_submitting &&
                  _error == null &&
                  service.canManage &&
                  service.canClose
              ? _close
              : null,
          child: const Text('신청 마감'),
        ),
      ),
    ],
  );

  static String _format(DateTime date) =>
      DateFormat('yyyy.MM.dd HH:mm').format(date);
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.service});
  final LifeService service;
  @override
  Widget build(BuildContext context) {
    final text = switch (service.status) {
      LifeServiceDisplayStatus.recruiting => '신청 접수 중',
      LifeServiceDisplayStatus.closed => '신청 마감',
      LifeServiceDisplayStatus.completed => '완료',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF006FFF),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 14,
          color: Color(0xFF464A4D),
        ),
      ),
      const SizedBox(height: 14),
      child,
    ],
  );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 76,
          child: Text(label, style: const TextStyle(color: Color(0xFF757B80))),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../widgets/life_service_style.dart';
import 'package:building_manage_front/core/constants/user_types.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/shared/widgets/refreshable_content.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/life_service.dart';
import '../providers/life_service_providers.dart';

class LifeServiceListScreen extends ConsumerStatefulWidget {
  const LifeServiceListScreen({super.key});
  @override
  ConsumerState<LifeServiceListScreen> createState() =>
      _LifeServiceListScreenState();
}

class _LifeServiceListScreenState extends ConsumerState<LifeServiceListScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _loading = true;
  int _loadRequest = 0;
  String? _error;
  List<LifeService> _items = const [];

  bool get _isResident =>
      ref.read(currentUserProvider)?.userType == UserType.user;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)..addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.removeListener(_onTabChanged);
    _tabs.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabs.indexIsChanging) _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tab = _isResident
          ? 'active'
          : (_tabs.index == 0 ? 'active' : 'completed');
      final items = await ref.read(lifeServiceUseCasesProvider).list(tab: tab);
      if (mounted && request == _loadRequest) setState(() => _items = items);
    } catch (e) {
      if (mounted && request == _loadRequest) {
        setState(
          () => _error = userMessageOf(e, fallback: '신청 가능한 서비스를 불러오지 못했습니다.'),
        );
      }
    } finally {
      if (mounted && request == _loadRequest) setState(() => _loading = false);
    }
  }

  Future<void> _open(String id) async {
    await context.pushNamed<bool>(
      'lifeServiceDetail',
      pathParameters: {'lifeServiceId': id},
    );
    if (mounted) await _load();
  }

  Future<void> _create() async {
    final changed = await context.pushNamed<bool>('lifeServiceCreate');
    if (changed == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return LifeServiceStyle(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF17191A),
          title: Text(
            _isResident
                ? '서비스 신청'
                : (ref.watch(currentUserProvider)?.buildingName ?? '서비스 신청 관리'),
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          bottom: _isResident
              ? null
              : PreferredSize(
                  preferredSize: const Size.fromHeight(108),
                  child: Column(
                    children: [
                      Container(
                        height: 60,
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Color(0xFFE8EEF2)),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                '서비스 신청 관리',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _create,
                              style: TextButton.styleFrom(
                                backgroundColor: const Color(0xFF006FFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('등록'),
                            ),
                          ],
                        ),
                      ),
                      TabBar(
                        controller: _tabs,
                        labelColor: const Color(0xFF006FFF),
                        unselectedLabelColor: const Color(0xFF757B80),
                        indicatorColor: const Color(0xFF006FFF),
                        tabs: const [
                          Tab(text: '진행 중'),
                          Tab(text: '완료'),
                        ],
                      ),
                    ],
                  ),
                ),
          actions: [
            if (_isResident)
              TextButton(
                onPressed: () async {
                  await context.pushNamed('lifeServiceHistory');
                  if (mounted) await _load();
                },
                child: const Text('지난 신청'),
              ),
          ],
        ),
        body: RefreshableContent(
          onRefresh: _load,
          isLoading: _loading && _items.isEmpty,
          error: _error,
          isEmpty: _items.isEmpty,
          emptyMessage: _isResident
              ? '현재 신청 가능한 서비스가 없습니다.'
              : '등록된 신청 항목이 없습니다.',
          child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: _items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFE8EEF2)),
            itemBuilder: (_, index) => LifeServiceCard(
              service: _items[index],
              residentMode: _isResident,
              onTap: () => _open(_items[index].id),
            ),
          ),
        ),
      ),
    );
  }
}

class LifeServiceCard extends StatelessWidget {
  const LifeServiceCard({
    super.key,
    required this.service,
    required this.residentMode,
    required this.onTap,
  });
  final LifeService service;
  final bool residentMode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final applied =
        service.applicationStatus == LifeServiceApplicationStatus.applied;
    final label = residentMode
        ? (service.status == LifeServiceDisplayStatus.closed
              ? (applied ? '신청 완료 · 신청 마감' : '신청 마감')
              : applied
              ? '신청 완료'
              : service.status == LifeServiceDisplayStatus.recruiting
              ? '신청 가능'
              : '신청 마감')
        : switch (service.status) {
            LifeServiceDisplayStatus.recruiting => '신청 접수 중',
            LifeServiceDisplayStatus.closed => '신청 마감',
            LifeServiceDisplayStatus.completed => '완료',
          };
    final blue =
        applied || service.status == LifeServiceDisplayStatus.recruiting;
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      service.title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: blue
                          ? const Color(0xFFEAF3FF)
                          : const Color(0xFFF2F4F5),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: blue
                            ? const Color(0xFF006FFF)
                            : const Color(0xFF757B80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${DateFormat('yyyy.MM.dd HH:mm').format(service.serviceStartAt)} ~ ${DateFormat('MM.dd HH:mm').format(service.serviceEndAt)}',
                style: const TextStyle(fontSize: 13, color: Color(0xFF464A4D)),
              ),
              const SizedBox(height: 4),
              Text(
                '신청 마감 ${DateFormat('yyyy.MM.dd HH:mm').format(service.applicationEndAt)}',
                style: const TextStyle(fontSize: 12, color: Color(0xFF757B80)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

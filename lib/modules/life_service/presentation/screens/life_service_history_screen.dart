import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/shared/widgets/refreshable_content.dart';
import '../../domain/entities/life_service.dart';
import '../providers/life_service_providers.dart';
import 'life_service_list_screen.dart';
import '../widgets/life_service_style.dart';

class LifeServiceHistoryScreen extends ConsumerStatefulWidget {
  const LifeServiceHistoryScreen({super.key});
  @override
  ConsumerState<LifeServiceHistoryScreen> createState() =>
      _LifeServiceHistoryScreenState();
}

class _LifeServiceHistoryScreenState
    extends ConsumerState<LifeServiceHistoryScreen> {
  bool _loading = true;
  int _loadRequest = 0;
  String? _error;
  List<LifeService> _items = const [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _open(String id) async {
    await context.pushNamed(
      'lifeServiceDetail',
      pathParameters: {'lifeServiceId': id},
    );
    if (mounted) await _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref.read(lifeServiceUseCasesProvider).history();
      if (mounted && request == _loadRequest) setState(() => _items = items);
    } catch (e) {
      if (mounted && request == _loadRequest) {
        setState(
          () => _error = userMessageOf(e, fallback: '신청 내역을 불러오지 못했습니다.'),
        );
      }
    } finally {
      if (mounted && request == _loadRequest) setState(() => _loading = false);
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
        title: const Text(
          '지난 신청 내역',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: RefreshableContent(
        onRefresh: _load,
        isLoading: _loading && _items.isEmpty,
        error: _error,
        isEmpty: _items.isEmpty,
        emptyMessage: '지난 신청 내역이 없습니다.',
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, color: Color(0xFFE8EEF2)),
          itemBuilder: (_, i) => Stack(
            children: [
              LifeServiceCard(
                service: _items[i],
                residentMode: true,
                onTap: () => _open(_items[i].id),
              ),
              if (_items[i].applicationStatus ==
                  LifeServiceApplicationStatus.canceled)
                const Positioned(
                  right: 16,
                  bottom: 12,
                  child: Text(
                    '취소됨',
                    style: TextStyle(
                      color: Color(0xFFE34D59),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

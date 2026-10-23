import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/shared/widgets/refreshable_content.dart';
import '../providers/life_service_providers.dart';
import '../widgets/life_service_style.dart';

class LifeServiceApplicantListScreen extends ConsumerStatefulWidget {
  const LifeServiceApplicantListScreen({
    super.key,
    required this.lifeServiceId,
  });
  final String lifeServiceId;
  @override
  ConsumerState<LifeServiceApplicantListScreen> createState() =>
      _LifeServiceApplicantListScreenState();
}

class _LifeServiceApplicantListScreenState
    extends ConsumerState<LifeServiceApplicantListScreen> {
  final _search = TextEditingController();
  bool _loading = true;
  int _loadRequest = 0;
  String? _error;
  List<Map<String, dynamic>> _items = const [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    final request = ++_loadRequest;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await ref
          .read(lifeServiceUseCasesProvider)
          .applicants(widget.lifeServiceId, keyword: _search.text.trim());
      if (mounted && request == _loadRequest) setState(() => _items = items);
    } catch (e) {
      if (mounted && request == _loadRequest) {
        setState(
          () => _error = userMessageOf(e, fallback: '신청자 명단을 불러오지 못했습니다.'),
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
          '신청자 명단',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: '이름 또는 동·호수 검색',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.arrow_forward),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '신청 ${_items.length}명',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshableContent(
              onRefresh: _load,
              isLoading: _loading && _items.isEmpty,
              error: _error,
              isEmpty: _items.isEmpty,
              emptyMessage: '신청자가 없습니다.',
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final item = _items[i];
                  return ListTile(
                    title: Text(item['name']?.toString() ?? '-'),
                    subtitle: Text(
                      '${item['dong'] ?? '-'}동 ${item['hosu'] ?? '-'}호',
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

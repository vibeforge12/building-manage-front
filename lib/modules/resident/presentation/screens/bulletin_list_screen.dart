import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/resident/data/datasources/bulletin_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/domain/entities/bulletin.dart';

/// 입주민 공고문 목록.
///
/// 목록은 공지사항과 같은 제목+날짜 한 줄이다. 사진은 상세에서 보여준다.
/// 입주민에게는 서버가 지금 게시 중인 것만 내려주므로 만료·예약·숨김 공고문은 여기 오지 않는다.
class BulletinListScreen extends ConsumerStatefulWidget {
  const BulletinListScreen({super.key});

  @override
  ConsumerState<BulletinListScreen> createState() => _BulletinListScreenState();
}

class _BulletinListScreenState extends ConsumerState<BulletinListScreen> {
  bool _isLoading = true;
  List<Bulletin> _bulletins = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBulletins();
  }

  Future<void> _loadBulletins() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final dataSource = ref.read(bulletinRemoteDataSourceProvider);
      final response = await dataSource.getBulletins(limit: 100);

      if (response['success'] == true && response['data'] != null) {
        if (mounted) {
          setState(() {
            _bulletins = _extractItems(response['data'])
                .map((json) => Bulletin.fromJson(json))
                .toList();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = '공고문을 불러올 수 없습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Bulletin Load Error: $e');
      if (mounted) {
        setState(() {
          _error = '공고문을 불러오는 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  /// 목록 응답에서 항목 배열을 꺼낸다.
  ///
  /// 공고문 API 는 { data: { data: [...], total, page } } 형태지만, 이 저장소의 다른
  /// 목록 응답은 { data: { items: [...] } } 이거나 { data: [...] } 인 곳도 있다.
  /// 서버가 하나로 통일되기 전까지 세 형태를 모두 받아 넘긴다.
  List<Map<String, dynamic>> _extractItems(dynamic data) {
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    if (data is Map) {
      final items = data['data'] ?? data['items'];
      if (items is List) return items.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  String _formatDate(DateTime date) => DateFormat('yyyy.MM.dd').format(date);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildNavigationBar(),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF006FFF),
                        ),
                      ),
                    )
                  : _error != null
                      ? _buildErrorState()
                      : _bulletins.isEmpty
                          ? _buildEmptyState()
                          : _buildBulletinList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationBar() {
    return Container(
      height: 48,
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
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => context.pop(),
            padding: const EdgeInsets.all(12),
          ),
          const Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '공고문',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF17191A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(0xFF757B80)),
          const SizedBox(height: 16),
          Text(
            _error!,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF757B80),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadBulletins,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006FFF),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              '다시 시도',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.campaign_outlined, size: 48, color: Color(0xFF757B80)),
          SizedBox(height: 16),
          Text(
            '등록된 공고문이 없습니다.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF757B80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletinList() {
    return RefreshIndicator(
      onRefresh: _loadBulletins,
      color: const Color(0xFF006FFF),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _bulletins.length,
        separatorBuilder: (context, index) => const Divider(
          // 항목 사이를 가로지르는 선은 앱 공통으로 2px 이다.
          height: 2,
          thickness: 2,
          color: Color(0xFFE8EEF2),
        ),
        itemBuilder: (context, index) => _buildBulletinItem(_bulletins[index]),
      ),
    );
  }

  Widget _buildBulletinItem(Bulletin bulletin) {
    return InkWell(
      onTap: bulletin.id.isEmpty
          ? null
          : () => context.pushNamed(
                'userBulletinDetail',
                pathParameters: {'bulletinId': bulletin.id},
              ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bulletin.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Color(0xFF17191A),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        _formatDate(bulletin.createdAt),
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 13,
                          color: Color(0xFF757B80),
                        ),
                      ),
                      // 사진이 목록에 보이지 않으므로, 사진이 붙어 있다는 것만 표시한다.
                      // 이게 없으면 이미지만 있는 공고문이 제목뿐인 빈 글로 보인다.
                      if (bulletin.hasImages) ...[
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.image_outlined,
                          size: 14,
                          color: Color(0xFF757B80),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${bulletin.imageUrls.length}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 13,
                            color: Color(0xFF757B80),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.chevron_right,
              size: 20,
              color: Color(0xFF757B80),
            ),
          ],
        ),
      ),
    );
  }
}

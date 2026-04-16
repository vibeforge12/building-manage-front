import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/resident/data/datasources/notice_remote_datasource.dart';
import 'package:intl/intl.dart';

class NoticeListScreen extends ConsumerStatefulWidget {
  const NoticeListScreen({super.key});

  @override
  ConsumerState<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends ConsumerState<NoticeListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notices = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  Future<void> _loadNotices() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getNotices();

      debugPrint('📋 Notice API Response: $response');

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        List<dynamic> items;

        // 페이지네이션 응답: { data: { items: [...] } } 또는 직접 리스트: { data: [...] }
        if (data is List) {
          items = data;
        } else if (data is Map && data['items'] != null) {
          items = data['items'] as List<dynamic>;
        } else {
          items = [];
        }

        if (mounted) {
          setState(() {
            _notices = items.cast<Map<String, dynamic>>();
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _error = '공지사항을 불러올 수 없습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Notice Load Error: $e');
      if (mounted) {
        setState(() {
          _error = '공지사항 로드 중 오류가 발생했습니다.';
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString).toLocal();
      return DateFormat('yyyy.MM.dd').format(dateTime);
    } catch (e) {
      return '';
    }
  }

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
                      : _notices.isEmpty
                          ? _buildEmptyState()
                          : _buildNoticeList(),
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
                '공지사항',
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
          const Icon(
            Icons.error_outline,
            size: 48,
            color: Color(0xFF757B80),
          ),
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
            onPressed: _loadNotices,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006FFF),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
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
          Icon(
            Icons.article_outlined,
            size: 48,
            color: Color(0xFF757B80),
          ),
          SizedBox(height: 16),
          Text(
            '등록된 공지사항이 없습니다.',
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

  Widget _buildNoticeList() {
    return RefreshIndicator(
      onRefresh: _loadNotices,
      color: const Color(0xFF006FFF),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: _notices.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          color: Color(0xFFE8EEF2),
        ),
        itemBuilder: (context, index) {
          final notice = _notices[index];
          return _buildNoticeItem(notice);
        },
      ),
    );
  }

  Widget _buildNoticeItem(Map<String, dynamic> notice) {
    final String id = notice['id']?.toString() ?? '';
    final String title = notice['title'] ?? '';
    final String date = _formatDate(notice['createdAt']);

    return InkWell(
      onTap: id.isNotEmpty
          ? () {
              context.pushNamed(
                'userNoticeDetail',
                pathParameters: {'noticeId': id},
              );
            }
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                  Text(
                    date,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 13,
                      color: Color(0xFF757B80),
                    ),
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

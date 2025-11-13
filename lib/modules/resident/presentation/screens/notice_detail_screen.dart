import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/resident/data/datasources/notice_remote_datasource.dart';
import 'package:intl/intl.dart';

class NoticeDetailScreen extends StatefulWidget {
  final String noticeId;

  const NoticeDetailScreen({
    super.key,
    required this.noticeId,
  });

  @override
  State<NoticeDetailScreen> createState() => _NoticeDetailScreenState();
}

class _NoticeDetailScreenState extends State<NoticeDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _notice;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNoticeDetail();
  }

  Future<void> _loadNoticeDetail() async {
    try {
      print('🎬 NoticeDetailScreen - noticeId: ${widget.noticeId}');

      // Riverpod에 접근하기 위해 직접 provider 인스턴스 사용
      final container = ProviderContainer();
      final noticeDataSource = container.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getNoticeDetail(noticeId: widget.noticeId);
      print('📦 NoticeDetailScreen - response: $response');

      // API 응답 구조: response = { success: true, data: { id, title, content, imageUrl, createdAt, ... } }
      if (response['success'] == true && response['data'] != null) {
        final noticeData = response['data'] as Map<String, dynamic>;
        print('✅ NoticeDetailScreen - 데이터 로드 성공: $noticeData');
        if (mounted) {
          setState(() {
            _notice = noticeData;
            _isLoading = false;
          });
        }
      } else {
        print('❌ NoticeDetailScreen - success가 false 또는 data가 null');
        if (mounted) {
          setState(() {
            _error = '공지사항을 불러올 수 없습니다.';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('❌ 공지사항 상세 조회 실패: $e');
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
      final dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy년 MM월 dd일 HH:mm').format(dateTime);
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
            // 네비게이션 바
            _buildNavigationBar(),
            // 콘텐츠
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
                      ? Center(
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
                                onPressed: () => context.pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006FFF),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: const Text(
                                  '뒤로가기',
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
                        )
                      : SingleChildScrollView(
                          child: _buildNoticeContent(),
                        ),
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
          // 뒤로가기 버튼
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => context.pop(),
            padding: const EdgeInsets.all(12),
          ),

          // 제목
          Expanded(
            child: const Align(
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

          // 오른쪽 액션 (확인 버튼 자리)
          SizedBox(
            width: 48,
            height: 48,
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeContent() {
    if (_notice == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 작성일 (맨 좌측에 붙음)
        Padding(
          padding: const EdgeInsets.only(top: 12, left: 16),
          child: Text(
            '작성일 : ${_formatDate(_notice!['createdAt'])}',
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 12,
              color: Color(0xFF757B80),
            ),
          ),
        ),

        // 전체 너비의 divider
        Container(
          height: 1,
          color: const Color(0xFFE8EEF2),
          margin: const EdgeInsets.only(top: 12),
        ),

        // 컨텐츠
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                _notice!['title'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: Color(0xFF17191A),
                  height: 1.25,
                ),
              ),

              const SizedBox(height: 16),

              // 구분선
              Container(
                height: 1,
                color: const Color(0xFFE8EEF2),
              ),

              const SizedBox(height: 24),

              // 본문
              Text(
                _notice!['content'] ?? '',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xFF464A4D),
                  height: 1.8,
                ),
              ),

              const SizedBox(height: 32),

              // 이미지 (있으면 표시) - 본문 아래에 위치
              if (_notice!['imageUrl'] != null &&
                  (_notice!['imageUrl'] is String) &&
                  (_notice!['imageUrl'] as String).isNotEmpty)
                Container(
                  width: double.infinity,
                  height: 200,
                  color: const Color(0xFFF5F5F5),
                  child: CachedNetworkImage(
                    imageUrl: _notice!['imageUrl'] as String,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFFE8EEF2),
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF5F5F5),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Color(0xFFCCCCCC),
                          size: 48,
                        ),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

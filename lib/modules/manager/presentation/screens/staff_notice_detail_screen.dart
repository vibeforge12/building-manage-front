import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/manager/data/datasources/staff_complaints_remote_datasource.dart';

class StaffNoticeDetailScreen extends StatefulWidget {
  final String noticeId;

  const StaffNoticeDetailScreen({
    super.key,
    required this.noticeId,
  });

  @override
  State<StaffNoticeDetailScreen> createState() => _StaffNoticeDetailScreenState();
}

class _StaffNoticeDetailScreenState extends State<StaffNoticeDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _noticeData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNoticeDetail();
  }

  Future<void> _loadNoticeDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use ProviderContainer to access Riverpod provider
      final container = ProviderContainer();
      final dataSource = container.read(staffComplaintsRemoteDataSourceProvider);
      final response = await dataSource.getNoticeDetail(widget.noticeId);

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _noticeData = response['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '공지사항을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 공지사항 상세 조회 실패: $e');
      setState(() {
        _error = '공지사항 로드 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
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
                          onPressed: _loadNoticeDetail,
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
                  )
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 네비게이션 바
                        Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                        ),
                        // 이미지
                        if (_noticeData?['imageUrl'] != null &&
                            (_noticeData?['imageUrl'] as String?)?.isNotEmpty == true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: CachedNetworkImage(
                              imageUrl: _noticeData!['imageUrl'] as String,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 240,
                              progressIndicatorBuilder: (context, url, downloadProgress) {
                                return Container(
                                  color: const Color(0xFFF2F8FC),
                                  height: 240,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: downloadProgress.progress,
                                      color: const Color(0xFF006FFF),
                                    ),
                                  ),
                                );
                              },
                              errorWidget: (context, url, error) => Container(
                                color: const Color(0xFFF2F8FC),
                                height: 240,
                                child: const Center(
                                  child: Icon(
                                    Icons.error,
                                    color: Color(0xFFA4ADB2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 제목
                              Text(
                                _noticeData?['title'] ?? '제목없음',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 20,
                                  color: Color(0xFF000000),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 제목 밑 구분선
                        Container(
                          height: 1,
                          color: const Color(0xFFE8EEF2),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          child: Text(
                            _noticeData?['content'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 16,
                              color: Color(0xFF464A4D),
                              height: 1.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}

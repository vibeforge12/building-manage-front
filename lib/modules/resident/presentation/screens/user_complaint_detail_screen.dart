import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

class UserComplaintDetailScreen extends StatefulWidget {
  final String complaintId;
  final Map<String, dynamic> complaintData;

  const UserComplaintDetailScreen({
    super.key,
    required this.complaintId,
    required this.complaintData,
  });

  @override
  State<UserComplaintDetailScreen> createState() => _UserComplaintDetailScreenState();
}

class _UserComplaintDetailScreenState extends State<UserComplaintDetailScreen> {
  late Map<String, dynamic> _complaint;

  @override
  void initState() {
    super.initState();
    _complaint = widget.complaintData;
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF17191A)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '내 민원 보기',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF17191A),
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 원본 민원 댓글
            _buildComplaintComment(_complaint),

            // 처리 결과가 있을 경우
            if (_complaint['isResolved'] == true &&
                (_complaint['results'] as List?)?.isNotEmpty == true)
              ...[
                // 진행 라인
                _buildProgressLine(),

                // 처리 결과 댓글들
                ...(_complaint['results'] as List<dynamic>)
                    .map((result) => _buildResultComment(result))
                    .toList(),
              ]
            else if (_complaint['isResolved'] != true)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEEEE6),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: Color(0xFFFF6B35),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '처리 중입니다. 곧 결과를 알려드리겠습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// 원본 민원 댓글 구성
  Widget _buildComplaintComment(Map<String, dynamic> complaint) {
    final title = complaint['title'] as String? ?? '';
    final content = complaint['content'] as String? ?? '';
    final imageUrl = complaint['imageUrl'] as String?;
    final createdAt = complaint['createdAt'] as String?;
    final departmentName = (complaint['department'] as Map<String, dynamic>?)
        ?['name'] as String? ?? '부서명';
    final isResolved = complaint['isResolved'] as bool? ?? false;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 사용자 정보 + 시간
          Row(
            children: [
              const Icon(Icons.person, size: 20, color: Color(0xFF464A4D)),
              const SizedBox(width: 8),
              const Text(
                '나',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF17191A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(createdAt),
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFF757B80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 구분선
          Container(
            height: 1,
            color: const Color(0xFFE8EEF2),
          ),
          const SizedBox(height: 12),

          // 제목
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Color(0xFF17191A),
            ),
          ),
          const SizedBox(height: 8),

          // 내용
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF464A4D),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // 이미지
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006FFF),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // 부서 정보
          Row(
            children: [
              const Icon(Icons.business, size: 16, color: Color(0xFF757B80)),
              const SizedBox(width: 8),
              Text(
                '부서: $departmentName',
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFF757B80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isResolved ? const Color(0xFFEEF5FF) : const Color(0xFFFEEEE6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isResolved ? '처리완료' : '처리필요',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: isResolved ? const Color(0xFF006FFF) : const Color(0xFFFF6B35),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 처리 결과 댓글 구성
  Widget _buildResultComment(dynamic result) {
    final content = result['content'] as String? ?? '';
    final imageUrl = result['imageUrl'] as String?;
    final createdAt = result['createdAt'] as String?;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 담당자 정보 + 시간
          Row(
            children: [
              const Icon(Icons.verified, size: 20, color: Color(0xFF006FFF)),
              const SizedBox(width: 8),
              const Text(
                '담당자',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Color(0xFF17191A),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(createdAt),
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFF757B80),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 구분선
          Container(
            height: 1,
            color: const Color(0xFFE8EEF2),
          ),
          const SizedBox(height: 12),

          // 처리 내용
          Text(
            content,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              color: Color(0xFF464A4D),
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),

          // 처리 이미지
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8FC),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF006FFF),
                        strokeWidth: 2,
                      ),
                    ),
                  );
                },
                errorWidget: (context, url, error) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Color(0xFFFF6B6B),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 16),

          // 상태 배지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF5FF),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '처리완료',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: Color(0xFF006FFF),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 진행 라인
  Widget _buildProgressLine() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Container(
              width: 2,
              height: 32,
              color: const Color(0xFFE8EEF2),
            ),
          ],
        ),
      ),
    );
  }
}

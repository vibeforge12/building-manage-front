import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  final String complaintId;

  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  ConsumerState<ComplaintDetailScreen> createState() => _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final getComplaintDetailUseCase = ref.watch(getComplaintDetailUseCaseProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0, // 스크롤 시 색상 변화 방지
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF464A4D)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '민원 상세',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
          ),
        ),
      ),
      body: FutureBuilder(
        future: getComplaintDetailUseCase.execute(complaintId: widget.complaintId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF006FFF)),
            );
          }

          if (snapshot.hasError) {
            print('❌ 민원 상세 조회 에러: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Color(0xFFA4ADB2),
                  ),
                  const SizedBox(height: 16),
                  const Text('민원 정보를 불러올 수 없습니다.'),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: Color(0xFFA4ADB2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('데이터를 찾을 수 없습니다.'));
          }

          final complaint = snapshot.data as AdminComplaint;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE8EEF2), width: 1),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              complaint.title,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF17191A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _getStatusColor(complaint.status),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _getStatusLabel(complaint.status),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person, size: 16, color: Color(0xFFA4ADB2)),
                          const SizedBox(width: 4),
                          Text(
                            '${complaint.residentName} (${complaint.residentUnit})',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF757B80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16, color: Color(0xFFA4ADB2)),
                          const SizedBox(width: 4),
                          Text(
                            complaint.departmentName,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF757B80),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Color(0xFFA4ADB2)),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(complaint.createdAt),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFFA4ADB2),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),


                // 댓글 섹션 (민원 작성자의 글 + 처리 내용)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '내용',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 민원 작성자 댓글
                      _buildCommentItem(
                        name: complaint.residentName,
                        date: _formatDate(complaint.createdAt),
                        content: complaint.content,
                        imageUrl: complaint.imageUrl,
                        isAuthor: true,
                      ),

                      const SizedBox(height: 16),

                      // 처리 내용 댓글들
                      if (complaint.response != null && complaint.response!.isNotEmpty) ...[
                        _buildCommentItem(
                          name: '담당자',
                          date: _formatDate(complaint.updatedAt ?? DateTime.now()),
                          content: complaint.response!,
                          imageUrl: complaint.responseImageUrl,
                          isAuthor: false,
                        ),
                      ],
                    ],
                  ),
                ),

                const Divider(color: Color(0xFFE8EEF2), thickness: 1),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return const Color(0xFFFF6B6B);
      case 'PROCESSING':
        return const Color(0xFF006FFF);
      case 'COMPLETED':
        return const Color(0xFF006FFF);
      case 'REJECTED':
        return const Color(0xFF999999);
      default:
        return const Color(0xFFE8EEF2);
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return '신규';
      case 'PROCESSING':
        return '처리중';
      case 'COMPLETED':
        return '완료';
      case 'REJECTED':
        return '반려';
      default:
        return '신규';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// 댓글 형식의 아이템 빌드 - 사용자와 담당자 명확히 구분
  Widget _buildCommentItem({
    required String name,
    required String date,
    required String content,
    String? imageUrl,
    required bool isAuthor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAuthor ? const Color(0xFFF2F8FC) : Colors.white,
        border: Border.all(
          color: const Color(0xFFE8EEF2),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 구분 뱃지 + 이름 + 날짜
          Row(
            children: [
              // 구분 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAuthor ? const Color(0xFFE8F4FF) : const Color(0xFFF0F0F0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isAuthor ? '민원자' : '담당자',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: isAuthor ? const Color(0xFF006FFF) : const Color(0xFF757B80),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // 이름
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: Color(0xFF17191A),
                  ),
                ),
              ),
              // 날짜
              Text(
                date,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  color: Color(0xFFA4ADB2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          // 이미지 (있을 경우)
          if (imageUrl != null && imageUrl.isNotEmpty) ...[
            const SizedBox(height: 12),
            // 이미지 레이블
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: isAuthor ? const Color(0xFFF2F8FC) : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.image,
                    size: 14,
                    color: isAuthor ? const Color(0xFF006FFF) : const Color(0xFF757B80),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isAuthor ? '민원자 첨부 이미지' : '담당자 답변 이미지',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                      color: isAuthor ? const Color(0xFF006FFF) : const Color(0xFF757B80),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 200,
                placeholder: (context, url) => Container(
                  color: const Color(0xFFF2F8FC),
                  height: 200,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: const Color(0xFFF2F8FC),
                  height: 200,
                  child: const Icon(Icons.error, color: Color(0xFFA4ADB2)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

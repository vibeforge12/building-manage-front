import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/shared/widgets/full_screen_image_viewer.dart';

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
      final dateTime = DateTime.parse(dateString).toLocal();
      return DateFormat('yyyy.MM.dd HH:mm').format(dateTime);
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isResolved = _complaint['isResolved'] == true;
    final imageUrl = _complaint['imageUrl'] as String?;
    final resident = _complaint['resident'] as Map<String, dynamic>?;
    final residentName = resident?['name'] as String? ?? '거주자명';
    final residentDong = resident?['dong'] as String? ?? '';
    final residentHosu = resident?['hosu'] as String? ?? '';
    final unit = [residentDong, residentHosu].where((e) => e.toString().isNotEmpty).join(' ');
    final department = _complaint['department'] as Map<String, dynamic>?;
    final departmentName = department?['name'] as String? ?? '-';
    final title = _complaint['title'] as String? ?? '제목없음';
    final content = _complaint['content'] as String? ?? '';
    final results = _complaint['results'] as List? ?? [];

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
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
                    bottom: BorderSide(color: Color(0xFFE8EEF2), width: 1),
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
                          '민원 상세',
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
              if (imageUrl != null && imageUrl.isNotEmpty)
                GestureDetector(
                  onTap: () => FullScreenImageViewer.show(context, imageUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(0),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 240,
                    progressIndicatorBuilder: (context, url, downloadProgress) => Container(
                      color: const Color(0xFFF2F8FC),
                      height: 240,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: downloadProgress.progress,
                          color: const Color(0xFF006FFF),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: const Color(0xFFF2F8FC),
                      height: 240,
                      child: const Center(child: Icon(Icons.error, color: Color(0xFFA4ADB2))),
                    ),
                    ),
                  ),
                ),
              // 처리 상태
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '처리 상태',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: isResolved
                                ? const Color(0xFFECFDF5)
                                : const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isResolved ? '처리 완료' : '미처리',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isResolved
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFD97706),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            departmentName,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              // 접수 시간
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '접수 시간',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    Text(
                      _formatDate(_complaint['createdAt'] as String?),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF757B80),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              // 작성자
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '작성자',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      unit.isEmpty ? residentName : '$residentName ($unit)',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              // 제목
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '제목',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF17191A),
                      ),
                    ),
                  ],
                ),
              ),
              Container(height: 1, color: const Color(0xFFE8EEF2)),
              // 내용
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '내용',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
              // 처리 내용
              if (isResolved && results.isNotEmpty) ...[
                Container(height: 8, color: const Color(0xFFF2F8FC)),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '처리 내용',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...results.map((result) {
                        final resultContent = result['content'] as String? ?? '';
                        final resultImageUrl = result['imageUrl'] as String?;
                        final resultCreatedAt = result['createdAt'] as String?;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (resultCreatedAt != null)
                              Text(
                                _formatDate(resultCreatedAt),
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 12,
                                  color: Color(0xFF757B80),
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              resultContent,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 14,
                                color: Color(0xFF17191A),
                                height: 1.6,
                              ),
                            ),
                            if (resultImageUrl != null && resultImageUrl.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: GestureDetector(
                                  onTap: () => FullScreenImageViewer.show(context, resultImageUrl),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      resultImageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder: (context, error, stackTrace) =>
                                          const SizedBox.shrink(),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';
import 'package:building_manage_front/shared/widgets/full_screen_image_viewer.dart';

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
  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return DateFormat('yyyy.MM.dd HH:mm').format(dateTime.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    final getComplaintDetailUseCase = ref.watch(getComplaintDetailUseCaseProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: FutureBuilder(
          future: getComplaintDetailUseCase.execute(complaintId: widget.complaintId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Color(0xFF757B80)),
                    const SizedBox(height: 16),
                    const Text(
                      '민원 정보를 불러올 수 없습니다.',
                      style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF757B80)),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
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

            if (!snapshot.hasData) {
              return const Center(child: Text('데이터를 찾을 수 없습니다.'));
            }

            final complaint = snapshot.data as AdminComplaint;
            final isResolved = complaint.status.toUpperCase() == 'COMPLETED';

            return SingleChildScrollView(
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
                  if (complaint.imageUrl != null && complaint.imageUrl!.isNotEmpty)
                    GestureDetector(
                      onTap: () => FullScreenImageViewer.show(context, complaint.imageUrl!),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(0),
                        child: CachedNetworkImage(
                          imageUrl: complaint.imageUrl!,
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
                          child: const Center(
                            child: Icon(Icons.error, color: Color(0xFFA4ADB2)),
                          ),
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
                          _formatDate(complaint.createdAt),
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
                          complaint.residentUnit.isEmpty
                              ? complaint.residentName
                              : '${complaint.residentName} (${complaint.residentUnit})',
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
                          complaint.title,
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
                          complaint.content,
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
                  // 처리 내용 (완료된 경우)
                  if (isResolved && complaint.response != null && complaint.response!.isNotEmpty) ...[
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
                          if (complaint.completedAt != null || complaint.updatedAt != null)
                            Text(
                              _formatDate(complaint.completedAt ?? complaint.updatedAt),
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: Color(0xFF757B80),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            complaint.response!,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF17191A),
                              height: 1.6,
                            ),
                          ),
                          if (complaint.responseImageUrl != null &&
                              complaint.responseImageUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: GestureDetector(
                                onTap: () => FullScreenImageViewer.show(
                                  context,
                                  complaint.responseImageUrl!,
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: CachedNetworkImage(
                                    imageUrl: complaint.responseImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorWidget: (context, url, error) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

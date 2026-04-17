import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/manager/data/datasources/staff_complaints_remote_datasource.dart';

class StaffComplaintDetailScreen extends StatefulWidget {
  final String complaintId;

  const StaffComplaintDetailScreen({
    super.key,
    required this.complaintId,
  });

  @override
  State<StaffComplaintDetailScreen> createState() => _StaffComplaintDetailScreenState();
}

class _StaffComplaintDetailScreenState extends State<StaffComplaintDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _complaintData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadComplaintDetail();
  }

  Future<void> _loadComplaintDetail() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Use ProviderContainer to access Riverpod provider
      final container = ProviderContainer();
      final dataSource = container.read(staffComplaintsRemoteDataSourceProvider);
      final response = await dataSource.getComplaintDetail(widget.complaintId);

      debugPrint('민원 상세 응답: $response');
      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _complaintData = response['data'] as Map<String, dynamic>;
          debugPrint('민원 results: ${_complaintData?['results']}');
          debugPrint('민원 isResolved: ${_complaintData?['isResolved']}');
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '민원을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = '민원 로드 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
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
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _complaintData != null &&
              _complaintData!['isResolved'] != true
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () {
                      context.push(
                        '/manager/complaint-resolve/${widget.complaintId}',
                        extra: _complaintData?['title'] ?? '민원',
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '처리 등록',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
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
                          onPressed: _loadComplaintDetail,
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
                        if (_complaintData?['imageUrl'] != null &&
                            (_complaintData?['imageUrl'] as String?)?.isNotEmpty == true)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(0),
                            child: CachedNetworkImage(
                              imageUrl: _complaintData!['imageUrl'] as String,
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
                                  color: _complaintData?['isResolved'] == true
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _complaintData?['isResolved'] == true ? '처리 완료' : '미처리',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                    color: _complaintData?['isResolved'] == true
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
                                _formatDate(_complaintData?['createdAt'] as String?),
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
                                '${_complaintData?['resident']?['name'] ?? '거주자명'} (${_complaintData?['resident']?['dong'] ?? ''} ${_complaintData?['resident']?['hosu'] ?? ''})',
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
                                _complaintData?['title'] ?? '제목없음',
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
                                _complaintData?['content'] ?? '',
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
                        // 처리 결과 표시
                        if (_complaintData?['isResolved'] == true &&
                            _complaintData?['results'] != null &&
                            (_complaintData!['results'] as List).isNotEmpty)
                          ...[
                            Container(
                              height: 8,
                              color: const Color(0xFFF2F8FC),
                            ),
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
                                  ...(_complaintData!['results'] as List).map((result) {
                                    final content = result['content'] as String? ?? '';
                                    final imageUrl = result['imageUrl'] as String?;
                                    final createdAt = result['createdAt'] as String?;
                                    String formattedDate = '';
                                    if (createdAt != null) {
                                      try {
                                        final dt = DateTime.parse(createdAt).toLocal();
                                        formattedDate = '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                                      } catch (_) {}
                                    }
                                    return Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (formattedDate.isNotEmpty)
                                          Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontFamily: 'Pretendard',
                                              fontWeight: FontWeight.w400,
                                              fontSize: 12,
                                              color: Color(0xFF757B80),
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
                                        if (imageUrl != null && imageUrl.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 12),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                imageUrl,
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                                errorBuilder: (context, error, stackTrace) =>
                                                    const SizedBox.shrink(),
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

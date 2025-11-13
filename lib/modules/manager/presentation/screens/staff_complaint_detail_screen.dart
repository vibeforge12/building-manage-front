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

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _complaintData = response['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '민원을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 민원 상세 조회 실패: $e');
      setState(() {
        _error = '민원 로드 중 오류가 발생했습니다.';
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
                          CachedNetworkImage(
                            imageUrl: _complaintData!['imageUrl'] as String,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 240,
                            placeholder: (context, url) => Container(
                              color: const Color(0xFFF2F8FC),
                              height: 240,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: const Color(0xFFF2F8FC),
                              height: 240,
                              child: const Icon(
                                Icons.error,
                                color: Color(0xFFA4ADB2),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 24,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 제목
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _complaintData?['resident']?['name'] ??
                                            '거주자명',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          color: Color(0xFF17191A),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_complaintData?['resident']?['dong'] ?? ''}동 ${_complaintData?['resident']?['hosu'] ?? ''}호',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 12,
                                          color: Color(0xFF757B80),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    _formatDate(
                                      _complaintData?['createdAt'] as String?,
                                    ),
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 12,
                                      color: Color(0xFF757B80),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // 거주자명 밑 구분선 (화면 끝에서 끝까지)
                        Container(
                          height: 1,
                          color: const Color(0xFFE8EEF2),
                        ),
                        // 제목 (수직 중앙정렬)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                          ),
                          height: 56,
                          alignment: Alignment.center,
                          child: Text(
                            _complaintData?['title'] ?? '제목없음',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        // 제목 밑 구분선 (화면 끝에서 끝까지)
                        Container(
                          height: 1,
                          color: const Color(0xFFE8EEF2),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
                          child: Text(
                            _complaintData?['content'] ?? '',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              color: Color(0xFF17191A),
                              height: 1.6,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/resident/data/datasources/complaint_remote_datasource.dart';
import 'package:intl/intl.dart';

class MyComplaintListScreen extends ConsumerStatefulWidget {
  const MyComplaintListScreen({super.key});

  @override
  ConsumerState<MyComplaintListScreen> createState() => _MyComplaintListScreenState();
}

class _MyComplaintListScreenState extends ConsumerState<MyComplaintListScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _complaints = [];
  String? _error;
  int _page = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final complaintDataSource = ref.read(complaintRemoteDataSourceProvider);
      final response = await complaintDataSource.getMyComplaints(
        page: _page,
        limit: _limit,
      );

      if (response['success'] == true && response['data'] != null) {
        final items = List<Map<String, dynamic>>.from(response['data']['items'] ?? []);
        setState(() {
          _complaints = items;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '민원을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 내 민원 조회 실패: $e');
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

  String _getStatusLabel(bool isResolved) {
    return isResolved ? '처리완료' : '처리중';
  }

  Color _getStatusColor(bool isResolved) {
    return isResolved ? const Color(0xFF006FFF) : const Color(0xFFE8EEF2);
  }

  Color _getStatusTextColor(bool isResolved) {
    return isResolved ? Colors.white : const Color(0xFFA4ADB2);
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
                                onPressed: () => _loadComplaints(),
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
                      : _complaints.isEmpty
                          ? Center(
                              child: Text(
                                '민원이 없습니다.',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Color(0xFF757B80),
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _complaints.length,
                              itemBuilder: (context, index) {
                                final complaint = _complaints[index];
                                final isResolved = complaint['isResolved'] as bool? ?? false;
                                return _buildComplaintItem(complaint, isResolved);
                              },
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
          IconButton(
            icon: const Icon(Icons.arrow_back, size: 24),
            onPressed: () => context.pop(),
            padding: const EdgeInsets.all(12),
          ),
          const Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '내 민원 보기',
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

  Widget _buildComplaintItem(Map<String, dynamic> complaint, bool isResolved) {
    final title = complaint['title'] as String? ?? '';
    final createdAt = complaint['createdAt'] as String?;

    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EEF2),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () {
          // TODO: 민원 상세 조회 화면으로 이동
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // 민원 제목
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 16,
                        color: Color(0xFF17191A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // 상태 배지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _getStatusColor(isResolved),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusLabel(isResolved),
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: _getStatusTextColor(isResolved),
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

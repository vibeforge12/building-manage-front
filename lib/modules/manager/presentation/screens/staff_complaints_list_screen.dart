import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/manager/data/datasources/staff_complaints_remote_datasource.dart';

class StaffComplaintsListScreen extends StatefulWidget {
  const StaffComplaintsListScreen({super.key});

  @override
  State<StaffComplaintsListScreen> createState() => _StaffComplaintsListScreenState();
}

class _StaffComplaintsListScreenState extends State<StaffComplaintsListScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _complaints = [];
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;
  final int _pageSize = 20;
  int _tabIndex = 0; // 0: 처리필요, 1: 처리완료

  @override
  void initState() {
    super.initState();
    _loadComplaints();
  }

  Future<void> _loadComplaints({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final container = ProviderContainer();
      final dataSource = container.read(staffComplaintsRemoteDataSourceProvider);
      final response = await dataSource.getPendingComplaints(page: page, limit: _pageSize);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        final meta = data['meta'] as Map<String, dynamic>?;

        setState(() {
          _complaints = items?.map((item) => item as Map<String, dynamic>).toList() ?? [];
          _currentPage = page;
          _totalCount = meta?['total'] as int? ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = '민원을 불러올 수 없습니다.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 미완료 민원 목록 조회 실패: $e');
      setState(() {
        _error = '민원 로드 중 오류가 발생했습니다.';
        _isLoading = false;
      });
    }
  }

  void _changeTab(int index) {
    setState(() {
      _tabIndex = index;
      _currentPage = 1;
    });
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
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
                        '민원 관리',
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
            // 탭 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeTab(0),
                      child: Column(
                        children: [
                          Text(
                            '처리필요',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: _tabIndex == 0 ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 14,
                              color: _tabIndex == 0 ? const Color(0xFF17191A) : const Color(0xFF757B80),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_tabIndex == 0)
                            Container(
                              height: 2,
                              color: const Color(0xFF006FFF),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _changeTab(1),
                      child: Column(
                        children: [
                          Text(
                            '처리완료',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: _tabIndex == 1 ? FontWeight.w700 : FontWeight.w400,
                              fontSize: 14,
                              color: _tabIndex == 1 ? const Color(0xFF17191A) : const Color(0xFF757B80),
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_tabIndex == 1)
                            Container(
                              height: 2,
                              color: const Color(0xFF006FFF),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                                onPressed: _loadComplaints,
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
                          ? const Center(
                              child: Text(
                                '미완료 민원이 없습니다.',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w400,
                                  fontSize: 14,
                                  color: Color(0xFF757B80),
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: _complaints.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final complaint = _complaints[index];
                                final complaintId = complaint['id'] as String?;
                                final title = complaint['title'] as String? ?? '제목없음';
                                final resident = complaint['resident'] as Map<String, dynamic>?;
                                final residentName = resident?['name'] as String? ?? '거주자명';
                                final dong = resident?['dong'] as String? ?? '';
                                final hosu = resident?['hosu'] as String? ?? '';
                                final createdAt = complaint['createdAt'] as String?;
                                final isResolved = complaint['isResolved'] as bool? ?? false;
                                final subtitle = '${dong}동 $hosu호 $residentName';
                                final date = _formatDate(createdAt);

                                // 탭에 맞는 데이터만 표시
                                final shouldShow = (_tabIndex == 0 && !isResolved) || (_tabIndex == 1 && isResolved);
                                if (!shouldShow) {
                                  return const SizedBox.shrink();
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: const Color(0xFFE8EEF2),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: Color(0xFF17191A),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              subtitle,
                                              style: const TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w400,
                                                fontSize: 12,
                                                color: Color(0xFF757B80),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            date,
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
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: _tabIndex == 0 ? const Color(0xFFFEEEE6) : const Color(0xFFEEF5FF),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              _tabIndex == 0 ? '처리필요' : '처리완료',
                                              style: TextStyle(
                                                fontFamily: 'Pretendard',
                                                fontWeight: FontWeight.w500,
                                                fontSize: 12,
                                                color: _tabIndex == 0 ? const Color(0xFFFF6B35) : const Color(0xFF006FFF),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            height: 32,
                                            child: TextButton(
                                              onPressed: () {
                                                if (complaintId != null) {
                                                  context.push('/manager/complaint-detail/$complaintId');
                                                }
                                              },
                                              style: TextButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                                backgroundColor: const Color(0xFF006FFF),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                              ),
                                              child: const Text(
                                                '확인',
                                                style: TextStyle(
                                                  fontFamily: 'Pretendard',
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 12,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
            ),
            // 페이지네이션
            if (_complaints.isNotEmpty && _totalCount > _pageSize)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFFE8EEF2),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPage > 1)
                      ElevatedButton.icon(
                        onPressed: () => _loadComplaints(page: _currentPage - 1),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('이전'),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '$_currentPage / ${(_totalCount / _pageSize).ceil()}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF464A4D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentPage < (_totalCount / _pageSize).ceil())
                      ElevatedButton.icon(
                        onPressed: () => _loadComplaints(page: _currentPage + 1),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('다음'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

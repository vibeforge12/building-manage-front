import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';
import 'package:building_manage_front/modules/admin/domain/entities/complaint.dart';
import 'package:building_manage_front/modules/admin/domain/entities/pagination.dart';

class ComplaintManagementScreen extends ConsumerStatefulWidget {
  const ComplaintManagementScreen({super.key});

  @override
  ConsumerState<ComplaintManagementScreen> createState() => _ComplaintManagementScreenState();
}

class _ComplaintManagementScreenState extends ConsumerState<ComplaintManagementScreen> {
  int _tabIndex = 0; // 0: 받은 민원, 1: 처리된 민원
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshComplaintData();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      _refreshComplaintData();
    }
  }

  void _changeTab(int index) {
    setState(() {
      _tabIndex = index;
      _currentPage = 1;
    });
    _refreshComplaintData();
  }

  void _refreshComplaintData() {
    if (_tabIndex == 0) {
      ref.refresh(getPendingComplaintsUseCaseProvider);
    } else {
      ref.refresh(getResolvedComplaintsUseCaseProvider);
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
            // 탭 바 (Segmented Controls)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(color: Colors.white),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F8FC),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
                ),
                child: Row(
                  children: [
                    Expanded(child: _buildTabButton('받은 민원', 0)),
                    Expanded(child: _buildTabButton('처리된 민원', 1)),
                  ],
                ),
              ),
            ),
            // 콘텐츠
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => _changeTab(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: isSelected ? BorderRadius.circular(8) : BorderRadius.zero,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
            fontSize: 14,
            color: const Color(0xFF17191A),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final Future<PaginatedComplaintResponse> future = _tabIndex == 0
        ? ref.watch(getPendingComplaintsUseCaseProvider).execute(page: _currentPage, limit: _pageSize)
        : ref.watch(getResolvedComplaintsUseCaseProvider).execute(page: _currentPage, limit: _pageSize);

    return FutureBuilder<PaginatedComplaintResponse>(
      future: future,
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
                  '민원을 불러올 수 없습니다.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: Color(0xFF757B80),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshComplaintData,
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

        final data = snapshot.data;
        final items = data?.data ?? [];
        final total = data?.total ?? 0;

        if (items.isEmpty) {
          return const Center(
            child: Text(
              '민원이 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Color(0xFF757B80),
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final complaint = items[index];
                  final isResolved = complaint.status.toUpperCase() == 'COMPLETED';

                  return InkWell(
                    onTap: () => context.push('/admin/complaint-detail/${complaint.id}'),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // 좌측: 제목 및 거주자 정보
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  complaint.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: Color(0xFF17191A),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${complaint.residentUnit} ${complaint.residentName}'.trim(),
                                  style: const TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xFF464A4D),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
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
                    ),
                  );
                },
              ),
            ),
            // 페이지네이션
            if (total > _pageSize)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFE8EEF2), width: 1),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_currentPage > 1)
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _currentPage -= 1),
                        icon: const Icon(Icons.chevron_left),
                        label: const Text('이전'),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      '$_currentPage / ${(total / _pageSize).ceil()}',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xFF464A4D),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_currentPage < (total / _pageSize).ceil())
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _currentPage += 1),
                        icon: const Icon(Icons.chevron_right),
                        label: const Text('다음'),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

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
  int _selectedTabIndex = 0;
  int _currentPage = 1;
  final int _pageSize = 20;

  @override
  void dispose() {
    super.dispose();
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
      _currentPage = 1;
    });
    // 탭 변경 시 데이터 새로고침
    _refreshComplaintData();
  }

  void _refreshComplaintData() {
    // 탭에 따라 해당 provider를 무효화하여 새로운 데이터를 요청
    switch (_selectedTabIndex) {
      case 0:
        ref.refresh(getAllComplaintsUseCaseProvider);
        break;
      case 1:
        ref.refresh(getPendingComplaintsUseCaseProvider);
        break;
      case 2:
        ref.refresh(getResolvedComplaintsUseCaseProvider);
        break;
    }
  }

  Future<void> _onComplaintTap(String complaintId) async {
    context.push('/admin/complaint-detail/$complaintId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF464A4D)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '민원 관리',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: const Color(0xFFE8EEF2),
          ),
        ),
      ),
      body: Column(
        children: [
          // Chips Tab Style (전체 / 신규 민원 / 완료된 민원)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              spacing: 8,
              children: [
                _buildChip(0, '전체'),
                _buildChip(1, '신규 민원'),
                _buildChip(2, '완료된 민원'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildComplaintListForTab(_selectedTabIndex),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF006FFF) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? const Color(0xFF006FFF) : const Color(0xFFE8EEF2),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: isSelected ? Colors.white : const Color(0xFF464A4D),
          ),
        ),
      ),
    );
  }

  Widget _buildComplaintListForTab(int tabIndex) {
    // 탭 인덱스에 따라 적절한 useCase 선택
    late dynamic useCase;

    switch (tabIndex) {
      case 0: // 전체 민원
        useCase = ref.watch(getAllComplaintsUseCaseProvider);
        break;
      case 1: // 신규 민원
        useCase = ref.watch(getPendingComplaintsUseCaseProvider);
        break;
      case 2: // 완료된 민원
        useCase = ref.watch(getResolvedComplaintsUseCaseProvider);
        break;
      default:
        useCase = ref.watch(getAllComplaintsUseCaseProvider);
    }

    return _buildComplaintList(
      useCase: useCase,
      page: _currentPage,
    );
  }

  Widget _buildComplaintList({
    required dynamic useCase,
    required int page,
  }) {
    return FutureBuilder(
      future: useCase.execute(page: page, limit: _pageSize),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF006FFF)),
          );
        }

        if (snapshot.hasError) {
          return const Center(
            child: Text(
              '아직 등록된 민원이 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFA4ADB2),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: Text(
              '아직 등록된 민원이 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFA4ADB2),
              ),
            ),
          );
        }

        final response = snapshot.data as PaginatedComplaintResponse?;
        final complaints = response?.data ?? <AdminComplaint>[];

        if (complaints.isEmpty) {
          return const Center(
            child: Text(
              '아직 등록된 민원이 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: Color(0xFFA4ADB2),
              ),
            ),
          );
        }

        return SingleChildScrollView(
          child: Column(
            children: [
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: complaints.length,
                itemBuilder: (context, index) {
                  final complaint = complaints[index];
                  return _ComplaintListTile(
                    complaint: complaint,
                    onTap: () => _onComplaintTap(complaint.id),
                  );
                },
              ),
              // Pagination
              if (response!.totalPages > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: page > 1
                            ? () {
                                setState(() {
                                  _currentPage--;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(
                        '$page / ${response.totalPages}',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      IconButton(
                        onPressed: page < response.totalPages
                            ? () {
                                setState(() {
                                  _currentPage++;
                                });
                              }
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ComplaintListTile extends StatelessWidget {
  final AdminComplaint complaint;
  final VoidCallback onTap;

  const _ComplaintListTile({
    required this.complaint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FC),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // 왼쪽 컨텐츠 영역
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 제목 (Label L: 16px, 700, #17191A)
                  Text(
                    complaint.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.5,
                      color: Color(0xFF17191A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // 입주민 이름 + 부서 + 동호수 한 줄로 (Caption M: 14px, 400, #464A4D)
                  Text(
                    '${complaint.residentName} · ${complaint.departmentName} · ${_formatUnit(complaint.residentUnit)}',
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      height: 1.4285714285714286,
                      color: Color(0xFF464A4D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 오른쪽 화살표
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF757B80),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  /// 동호수 포맷팅 (101-1003 → 101동 1003호)
  String _formatUnit(String unit) {
    if (unit.isEmpty) return '';
    final parts = unit.split('-');
    if (parts.length == 2) {
      return '${parts[0]}동 ${parts[1]}호';
    }
    return unit;
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}

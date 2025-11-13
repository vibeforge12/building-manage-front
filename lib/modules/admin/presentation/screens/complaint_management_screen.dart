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
            child: IndexedStack(
              index: _selectedTabIndex,
              children: [
                // 전체 민원
                _buildComplaintList(
                  useCase: ref.watch(getAllComplaintsUseCaseProvider),
                  page: _currentPage,
                ),
                // 신규 민원
                _buildComplaintList(
                  useCase: ref.watch(getPendingComplaintsUseCaseProvider),
                  page: _currentPage,
                ),
                // 완료된 민원
                _buildComplaintList(
                  useCase: ref.watch(getResolvedComplaintsUseCaseProvider),
                  page: _currentPage,
                ),
              ],
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    complaint.title,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(complaint.status),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    complaint.statusLabel,
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
            const SizedBox(height: 8),
            // Resident Info
            Text(
              '${complaint.residentUnit} · ${complaint.residentName}',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFF757B80),
              ),
            ),
            const SizedBox(height: 6),
            // Department Info
            Text(
              complaint.departmentName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFA4ADB2),
              ),
            ),
            const SizedBox(height: 6),
            // Created Date
            Text(
              _formatDate(complaint.createdAt),
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Color(0xFFA4ADB2),
              ),
            ),
          ],
        ),
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
        return const Color(0xFF52C41A);
      case 'REJECTED':
        return const Color(0xFF999999);
      default:
        return const Color(0xFFE8EEF2);
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }
}

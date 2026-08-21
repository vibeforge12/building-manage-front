import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_attendance_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff_attendance.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

/// 관리자용 실시간 담당자 출퇴근 현황 화면.
/// 오늘 날짜의 daily endpoint 를 호출해 status(WORKING/LEFT/NOT_ARRIVED) 3단계로 표시.
class StaffAttendanceCurrentScreen extends ConsumerStatefulWidget {
  const StaffAttendanceCurrentScreen({super.key});

  @override
  ConsumerState<StaffAttendanceCurrentScreen> createState() =>
      _StaffAttendanceCurrentScreenState();
}

class _StaffAttendanceCurrentScreenState
    extends ConsumerState<StaffAttendanceCurrentScreen> {
  StaffAttendanceDaily? _data;
  bool _isLoading = false;
  String? _error;
  DateTime _refreshedAt = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final dataSource = ref.read(staffAttendanceRemoteDataSourceProvider);
      final result = await dataSource.getDailyStaffAttendance(
        year: now.year,
        month: now.month,
        day: now.day,
      );
      setState(() {
        _data = result;
        _refreshedAt = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is ApiException
            ? e.userFriendlyMessage
            : '실시간 현황을 불러올 수 없습니다.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 정렬 순위: 근무중 → 퇴근완료 → 미출근
  int _statusRank(String status) {
    switch (status) {
      case 'WORKING':
        return 0;
      case 'LEFT':
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final refreshedText =
        '${DateFormat('yyyy년 M월 d일 HH:mm', 'ko').format(_refreshedAt)} 기준';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '실시간 출퇴근 현황',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Color(0xFF006FFF)),
            onPressed: _load,
            tooltip: '새로고침',
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF2)),
        ),
      ),
      body: SafeArea(
        top: false, // AppBar 가 이미 상단 safe area 처리
        child: Column(
          children: [
            // 갱신 시각 바
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: const Color(0xFFF2F8FC),
              width: double.infinity,
              child: Text(
                refreshedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF464A4D),
                ),
              ),
            ),

            if (_data != null) _buildSummaryCards(_data!.staffs),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? _buildErrorView()
                      : _data == null || _data!.staffs.isEmpty
                          ? _buildEmptyView()
                          : RefreshIndicator(
                              onRefresh: _load,
                              child: _buildStaffList(_data!.staffs),
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffList(List<StaffDailyAttendance> staffs) {
    final sorted = [...staffs]
      ..sort((a, b) {
        final rankCompare = _statusRank(a.status).compareTo(_statusRank(b.status));
        if (rankCompare != 0) return rankCompare;
        return a.name.compareTo(b.name);
      });

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _buildStaffCard(sorted[index]),
    );
  }

  Widget _buildSummaryCards(List<StaffDailyAttendance> staffs) {
    final working = staffs.where((s) => s.status == 'WORKING').length;
    final left = staffs.where((s) => s.status == 'LEFT').length;
    final notArrived = staffs.where((s) => s.status == 'NOT_ARRIVED').length;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryItem('전체', staffs.length, const Color(0xFF006FFF)),
          const SizedBox(width: 8),
          _buildSummaryItem('근무중', working, const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildSummaryItem('퇴근', left, const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildSummaryItem('미출근', notArrived, const Color(0xFF9CA3AF)),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(StaffDailyAttendance staff) {
    final Color statusColor;
    final Color statusBgColor;
    final String statusLabel;

    switch (staff.status) {
      case 'WORKING':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFFECFDF5);
        statusLabel = '근무중';
        break;
      case 'LEFT':
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFFEF2F2);
        statusLabel = '퇴근';
        break;
      default:
        statusColor = const Color(0xFF9CA3AF);
        statusBgColor = const Color(0xFFF3F4F6);
        statusLabel = '미출근';
    }

    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_outline, size: 24, color: Color(0xFF006FFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.name,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF17191A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  staff.department?.name ?? '부서 미지정',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
                if (staff.checkIn != null || staff.checkOut != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      [
                        if (staff.checkIn != null)
                          '${timeFormat.format(staff.checkIn!)} 출근',
                        if (staff.checkOut != null)
                          '${timeFormat.format(staff.checkOut!)} 퇴근',
                      ].join(' · '),
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006FFF),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('다시 시도', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Color(0xFFE8EEF2)),
            SizedBox(height: 16),
            Text(
              '등록된 담당자가 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

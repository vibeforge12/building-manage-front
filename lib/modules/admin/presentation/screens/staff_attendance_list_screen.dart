import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_attendance_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff_attendance.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffAttendanceListScreen extends ConsumerStatefulWidget {
  const StaffAttendanceListScreen({super.key});

  @override
  ConsumerState<StaffAttendanceListScreen> createState() => _StaffAttendanceListScreenState();
}

class _StaffAttendanceListScreenState extends ConsumerState<StaffAttendanceListScreen> {
  StaffAttendanceDaily? _dailyData;
  bool _isLoading = false;
  String? _errorMessage;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = ref.read(staffAttendanceRemoteDataSourceProvider);
      final result = await dataSource.getDailyStaffAttendance(
        year: _selectedDate.year,
        month: _selectedDate.month,
        day: _selectedDate.day,
      );

      setState(() {
        _dailyData = result;
      });
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '출퇴근 현황을 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('ko'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('yyyy년 M월 d일 (E)', 'ko').format(_selectedDate);

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
          '담당자 출근 / 퇴근 목록',
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
            icon: const Icon(Icons.calendar_month, color: Color(0xFF006FFF)),
            onPressed: () => context.push('/admin/staff-attendance-calendar'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF2)),
        ),
      ),
      body: Column(
        children: [
          // 날짜 선택 바
          GestureDetector(
            onTap: _selectDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFFF2F8FC),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.calendar_today, size: 16, color: Color(0xFF006FFF)),
                  const SizedBox(width: 8),
                  Text(
                    dateText,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF17191A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, color: Color(0xFF006FFF)),
                ],
              ),
            ),
          ),

          // Summary 카드
          if (_dailyData != null) _buildSummaryCards(_dailyData!.summary),

          // 직원 리스트
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorView()
                    : _dailyData == null || _dailyData!.staffs.isEmpty
                        ? _buildEmptyView()
                        : RefreshIndicator(
                            onRefresh: _loadData,
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _dailyData!.staffs.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                return _buildStaffCard(_dailyData!.staffs[index]);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(AttendanceSummary summary) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildSummaryItem('전체', summary.total, const Color(0xFF006FFF)),
          const SizedBox(width: 8),
          _buildSummaryItem('근무중', summary.working, const Color(0xFF10B981)),
          const SizedBox(width: 8),
          _buildSummaryItem('퇴근', summary.left, const Color(0xFFEF4444)),
          const SizedBox(width: 8),
          _buildSummaryItem('미출근', summary.notArrived, const Color(0xFF9CA3AF)),
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
    Color statusColor;
    Color statusBgColor;

    switch (staff.status) {
      case 'WORKING':
        statusColor = const Color(0xFF10B981);
        statusBgColor = const Color(0xFFECFDF5);
        break;
      case 'LEFT':
        statusColor = const Color(0xFFEF4444);
        statusBgColor = const Color(0xFFFEF2F2);
        break;
      default:
        statusColor = const Color(0xFF9CA3AF);
        statusBgColor = const Color(0xFFF3F4F6);
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
                        if (staff.checkIn != null) '출근 ${timeFormat.format(staff.checkIn!)}',
                        if (staff.checkOut != null) '퇴근 ${timeFormat.format(staff.checkOut!)}',
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
              staff.statusText,
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
              _errorMessage!,
              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF6B7280)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006FFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              '출퇴근 기록이 없습니다.',
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_attendance_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/domain/entities/staff_attendance.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffAttendanceCalendarScreen extends ConsumerStatefulWidget {
  const StaffAttendanceCalendarScreen({super.key});

  @override
  ConsumerState<StaffAttendanceCalendarScreen> createState() =>
      _StaffAttendanceCalendarScreenState();
}

class _StaffAttendanceCalendarScreenState
    extends ConsumerState<StaffAttendanceCalendarScreen> {
  StaffAttendanceMonthly? _monthlyData;
  bool _isLoading = false;
  String? _errorMessage;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadMonthlyData();
  }

  Future<void> _loadMonthlyData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = ref.read(staffAttendanceRemoteDataSourceProvider);
      final result = await dataSource.getMonthlyStaffAttendance(
        year: _focusedDay.year,
        month: _focusedDay.month,
      );
      setState(() {
        _monthlyData = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '출퇴근 데이터를 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 특정 날짜에 출퇴근 기록이 있는 직원 수 계산
  // TODO(human): 캘린더 날짜별 마커 데이터 생성 로직 구현
  Map<String, int> _getAttendanceCountForDate(DateTime date) {
    if (_monthlyData == null) return {'total': 0, 'attended': 0};

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    int attended = 0;

    for (final staff in _monthlyData!.staffs) {
      final hasRecord = staff.days.any((d) => d.date == dateStr);
      if (hasRecord) attended++;
    }

    return {
      'total': _monthlyData!.staffs.length,
      'attended': attended,
    };
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
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '직원 출퇴근 캘린더',
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
            icon: const Icon(Icons.bolt, color: Color(0xFF006FFF)),
            tooltip: '실시간 현황',
            onPressed: () => context.push('/admin/staff-attendance-current'),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFE8EEF2)),
        ),
      ),
      body: SafeArea(
        top: false,
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : Column(
                  children: [
                    // 캘린더
                    TableCalendar(
                      firstDay: DateTime(2024, 1, 1),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: _focusedDay,
                      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                      calendarFormat: CalendarFormat.month,
                      locale: 'ko_KR',
                      headerStyle: const HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                        leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF006FFF)),
                        rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF006FFF)),
                      ),
                      calendarStyle: const CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: Color(0xFFE3F2FD),
                          shape: BoxShape.circle,
                        ),
                        todayTextStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF006FFF),
                        ),
                        selectedDecoration: BoxDecoration(
                          color: Color(0xFF006FFF),
                          shape: BoxShape.circle,
                        ),
                        selectedTextStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        defaultTextStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                        ),
                        weekendTextStyle: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, date, events) {
                          final counts = _getAttendanceCountForDate(date);
                          final attended = counts['attended'] ?? 0;
                          if (attended == 0) return null;

                          return Positioned(
                            bottom: 1,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0xFF006FFF),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '$attended명',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  fontSize: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      onDaySelected: (selectedDay, focusedDay) {
                        setState(() {
                          _selectedDay = selectedDay;
                          _focusedDay = focusedDay;
                        });
                      },
                      onPageChanged: (focusedDay) {
                        setState(() {
                          _focusedDay = focusedDay;
                          // 월 변경 시 선택일도 새 달로 동기화 → 하단 리스트도 새 달 기준
                          _selectedDay = focusedDay;
                        });
                        _loadMonthlyData();
                      },
                    ),

                    const Divider(height: 1, color: Color(0xFFE8EEF2)),

                    // 선택된 날짜의 직원 목록
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Text(
                            DateFormat('M월 d일 (E)', 'ko').format(_selectedDay),
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF17191A),
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              // 선택된 날짜의 일별 상세 화면으로 이동
                              context.push('/admin/staff-attendance-list');
                            },
                            child: const Text(
                              '상세 보기',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF006FFF),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 해당 날짜 직원 출퇴근 리스트
                    Expanded(
                      child: _buildDayStaffList(),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _buildDayStaffList() {
    if (_monthlyData == null) return const SizedBox();

    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDay);
    final staffsWithRecords = <Map<String, dynamic>>[];

    for (final staff in _monthlyData!.staffs) {
      final dayRecord = staff.days.where((d) => d.date == dateStr).firstOrNull;
      staffsWithRecords.add({
        'name': staff.name,
        'department': staff.department?.name ?? '부서 미지정',
        'checkIn': dayRecord?.checkIn,
        'checkOut': dayRecord?.checkOut,
        'hasRecord': dayRecord != null,
      });
    }

    // 출근한 직원을 먼저 표시
    staffsWithRecords.sort((a, b) {
      if (a['hasRecord'] == b['hasRecord']) return 0;
      return a['hasRecord'] ? -1 : 1;
    });

    if (staffsWithRecords.isEmpty) {
      return const Center(
        child: Text(
          '등록된 직원이 없습니다.',
          style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF9CA3AF)),
        ),
      );
    }

    final timeFormat = DateFormat('HH:mm');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: staffsWithRecords.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 2, thickness: 2, color: Color(0xFFF3F4F6)),
      itemBuilder: (context, index) {
        final data = staffsWithRecords[index];
        final hasRecord = data['hasRecord'] as bool;
        final checkIn = data['checkIn'] as DateTime?;
        final checkOut = data['checkOut'] as DateTime?;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] as String,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    Text(
                      data['department'] as String,
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 12,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasRecord)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (checkIn != null)
                      Text(
                        '${timeFormat.format(checkIn)} 출근',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF006FFF),
                        ),
                      ),
                    if (checkOut != null)
                      Text(
                        '${timeFormat.format(checkOut)} 퇴근',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFFFF1E00),
                        ),
                      ),
                  ],
                )
              else
                const Text(
                  '미출근',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
            ],
          ),
        );
      },
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
              onPressed: _loadMonthlyData,
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
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/manager/presentation/providers/attendance_history_provider.dart';
import 'package:building_manage_front/modules/manager/domain/entities/attendance_record.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class AttendanceHistoryScreen extends ConsumerStatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  ConsumerState<AttendanceHistoryScreen> createState() => _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends ConsumerState<AttendanceHistoryScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    // 초기 진입 시 오늘 날짜를 선택 상태로 → 리스트가 오늘 기록만 표시
    _selectedDay = DateTime.now();
    // 화면 로드 시 현재 월의 출퇴근 기록 조회
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendanceHistoryProvider.notifier).fetchMonthlyAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(attendanceHistoryProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF464A4D)),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '출근 / 퇴근 조회',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false, // AppBar 가 이미 상단 safe area 처리
        child: historyState.isLoading && historyState.records.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Calendar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildCalendar(historyState),
                  ),

                  // Separator
                  Container(
                    height: 8,
                    color: const Color(0xFFF2F8FC),
                  ),

                  // All attendance records list
                  Expanded(
                    child: _buildAttendanceList(historyState),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCalendar(AttendanceHistoryState historyState) {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: _focusedDay,
      locale: 'ko_KR', // 한국어 로케일 설정
      rowHeight: 56,
      selectedDayPredicate: (day) {
        if (_selectedDay == null) return false;
        // 오늘은 today 스타일(파랑) 유지하기 위해 selected 로 표시하지 않음
        if (isSameDay(day, DateTime.now())) return false;
        return isSameDay(day, _selectedDay);
      },
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          // 같은 날 재탭 → 선택 해제
          if (_selectedDay != null && isSameDay(_selectedDay, selectedDay)) {
            _selectedDay = null;
          } else {
            _selectedDay = selectedDay;
          }
          _focusedDay = focusedDay;
        });
      },
      onPageChanged: (focusedDay) {
        setState(() {
          _focusedDay = focusedDay;
          // 다른 달로 이동 시 선택 초기화
          _selectedDay = null;
        });
        // 월이 변경되면 해당 월의 데이터 조회
        ref.read(attendanceHistoryProvider.notifier).setYearMonth(
              focusedDay.year,
              focusedDay.month,
            );
      },
      calendarFormat: CalendarFormat.month,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        headerPadding: const EdgeInsets.only(bottom: 16),
        titleTextFormatter: (date, locale) {
          // 한국어 형식으로 표시: "2025년 11월"
          return '${date.year}년 ${date.month}월';
        },
        titleTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF17191A),
        ),
        leftChevronIcon: const Icon(
          Icons.chevron_left,
          color: Color(0xFF464A4D),
        ),
        rightChevronIcon: const Icon(
          Icons.chevron_right,
          color: Color(0xFF464A4D),
        ),
      ),
      daysOfWeekHeight: 40,
      daysOfWeekStyle: const DaysOfWeekStyle(
        weekdayStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFF17191A),
        ),
        weekendStyle: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFF17191A),
        ),
      ),
      calendarStyle: CalendarStyle(
        cellMargin: const EdgeInsets.all(4),
        defaultTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFF17191A),
        ),
        weekendTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFF17191A),
        ),
        todayDecoration: BoxDecoration(
          color: const Color(0xFFB3D4FF), // 연한 파랑
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Color(0xFF006FFF), // 진한 파랑 글자 (연한 배경 가독성)
        ),
        selectedDecoration: BoxDecoration(
          color: const Color(0xFF006FFF), // 진한 파랑
          shape: BoxShape.circle,
        ),
        selectedTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: Colors.white,
        ),
        outsideTextStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w400,
          fontSize: 16,
          color: Color(0xFFBDBDBD),
        ),
      ),
      calendarBuilders: CalendarBuilders(
        // Custom marker builder to show blue/red dots for check-in/check-out
        markerBuilder: (context, date, events) {
          if (date.month != _focusedDay.month) return const SizedBox.shrink();

          final hasCheckIn = historyState.hasCheckInOnDate(date);
          final hasCheckOut = historyState.hasCheckOutOnDate(date);

          if (!hasCheckIn && !hasCheckOut) return const SizedBox.shrink();

          return Positioned(
            bottom: 2,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (hasCheckIn)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      color: Color(0xFF006FFF), // Blue dot for check-in
                      shape: BoxShape.circle,
                    ),
                  ),
                if (hasCheckOut)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF1E00), // Red dot for check-out
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAttendanceList(AttendanceHistoryState historyState) {
    // 각 record 를 오래된순으로 필터 (선택일 또는 focused 월)
    final allRecords = [...historyState.records]
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final recordsToShow = _selectedDay != null
        ? allRecords.where((r) => isSameDay(r.createdAt, _selectedDay)).toList()
        : allRecords
            .where((r) =>
                r.createdAt.year == _focusedDay.year &&
                r.createdAt.month == _focusedDay.month)
            .toList();

    if (recordsToShow.isEmpty) {
      return Center(
        child: Text(
          _selectedDay != null
              ? '${_selectedDay!.month}월 ${_selectedDay!.day}일 출퇴근 기록이 없습니다'
              : '출퇴근 기록이 없습니다',
          style: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF757B80),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recordsToShow.length,
      itemBuilder: (context, index) {
        final record = recordsToShow[index];
        final isCheckIn = record.type == AttendanceRecordType.checkIn;
        final label = isCheckIn ? '출근' : '퇴근';
        final accent = isCheckIn ? const Color(0xFF006FFF) : const Color(0xFFFF1E00);
        final dayNum = record.createdAt.day;
        final timeStr = DateFormat('HH:mm').format(record.createdAt);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  '$dayNum일 - $timeStr',
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Color(0xFF17191A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

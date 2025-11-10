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

  @override
  void initState() {
    super.initState();
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
      body: historyState.isLoading && historyState.records.isEmpty
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
    );
  }

  Widget _buildCalendar(AttendanceHistoryState historyState) {
    return TableCalendar(
      firstDay: DateTime(2020, 1, 1),
      lastDay: DateTime(2030, 12, 31),
      focusedDay: _focusedDay,
      locale: 'ko_KR', // 한국어 로케일 설정
      rowHeight: 56,
      onPageChanged: (focusedDay) {
        _focusedDay = focusedDay;
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
          color: const Color(0xFF006FFF),
          shape: BoxShape.circle,
        ),
        todayTextStyle: const TextStyle(
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

          final hasCheckIn = historyState.hasCheckInOnDate(date.day);
          final hasCheckOut = historyState.hasCheckOutOnDate(date.day);

          if (!hasCheckIn && !hasCheckOut) return const SizedBox.shrink();

          return Positioned(
            bottom: -4,
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
    if (historyState.records.isEmpty) {
      return const Center(
        child: Text(
          '출퇴근 기록이 없습니다',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w400,
            fontSize: 14,
            color: Color(0xFF757B80),
          ),
        ),
      );
    }

    // 날짜별로 그룹화
    final Map<int, List<AttendanceRecord>> groupedRecords = {};
    for (var record in historyState.records) {
      final day = record.createdAt.day;
      if (!groupedRecords.containsKey(day)) {
        groupedRecords[day] = [];
      }
      groupedRecords[day]!.add(record);
    }

    // 날짜별로 정렬 (내림차순)
    final sortedDays = groupedRecords.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedDays.length,
      itemBuilder: (context, index) {
        final day = sortedDays[index];
        final records = groupedRecords[day]!;

        // 출근/퇴근 시간 찾기
        String? checkInTime;
        String? checkOutTime;

        for (var record in records) {
          final time = DateFormat('HH:mm').format(record.createdAt);
          if (record.type == AttendanceRecordType.checkIn) {
            checkInTime = time;
          } else if (record.type == AttendanceRecordType.checkOut) {
            checkOutTime = time;
          }
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header with time range
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${day}일  ${checkInTime ?? ''} ~ ${checkOutTime ?? ''}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Color(0xFF17191A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Check-in and check-out times
                        Row(
                          children: [
                            if (checkInTime != null) ...[
                              Text(
                                '오전 $checkInTime 출근',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF006FFF),
                                ),
                              ),
                              if (checkOutTime != null) ...[
                                const SizedBox(width: 8),
                                const Text(
                                  'ㅣ',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                    fontSize: 14,
                                    color: Color(0xFF464A4D),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ],
                            if (checkOutTime != null)
                              Text(
                                '오후 $checkOutTime 퇴근',
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: Color(0xFF006FFF),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF006FFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '근무',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        );
      },
    );
  }
}

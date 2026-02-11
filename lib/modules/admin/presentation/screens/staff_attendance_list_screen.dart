import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/admin/data/datasources/attendance_alert_remote_datasource.dart';
import 'package:building_manage_front/modules/admin/data/datasources/staff_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffAttendanceListScreen extends ConsumerStatefulWidget {
  const StaffAttendanceListScreen({super.key});

  @override
  ConsumerState<StaffAttendanceListScreen> createState() => _StaffAttendanceListScreenState();
}

class _StaffAttendanceListScreenState extends ConsumerState<StaffAttendanceListScreen> {
  List<Map<String, dynamic>> _allStaffs = []; // 모든 담당자 목록
  List<Map<String, dynamic>> _allAttendances = [];
  Map<String, List<Map<String, dynamic>>> _groupedByStaff = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    print('🚀 _loadData 시작');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 담당자 목록과 출근 기록을 동시에 가져오기
      final staffDataSource = ref.read(staffRemoteDataSourceProvider);
      final attendanceDataSource = ref.read(attendanceAlertRemoteDataSourceProvider);

      print('📤 API 호출 시작...');

      final results = await Future.wait([
        staffDataSource.getStaffs(),
        attendanceDataSource.getDashboardAlerts(),
      ]);

      print('📥 API 호출 완료');

      final staffResponse = results[0];
      final attendanceResponse = results[1];

      print('📋 staffResponse: $staffResponse');
      print('📋 attendanceResponse: $attendanceResponse');

      // 담당자 목록 파싱
      if (staffResponse['success'] == true) {
        final data = staffResponse['data'];
        // data가 List인 경우 (직접 배열 반환)
        if (data is List) {
          _allStaffs = data.cast<Map<String, dynamic>>();
        }
        // data가 Map인 경우 (items 안에 배열)
        else if (data is Map<String, dynamic>) {
          final items = data['items'] as List<dynamic>? ?? [];
          _allStaffs = items.cast<Map<String, dynamic>>();
        }
        print('✅ 담당자 목록 로드: ${_allStaffs.length}명');
      } else {
        print('❌ staffResponse success가 false');
      }

      // 출근 기록 파싱
      if (attendanceResponse['success'] == true) {
        final data = attendanceResponse['data'] as Map<String, dynamic>;
        final latestAttendances = data['latestAttendances'] as List<dynamic>? ?? [];
        _allAttendances = latestAttendances.cast<Map<String, dynamic>>();
        _groupAttendancesByStaff();
        print('✅ 출근 기록 로드: ${_allAttendances.length}건');
      } else {
        print('❌ attendanceResponse success가 false');
      }

      setState(() {});
    } catch (e, stackTrace) {
      print('❌ _loadData 에러: $e');
      print('📋 스택 트레이스: $stackTrace');
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '목록을 불러오는 중 오류가 발생했습니다.';
        }
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 담당자별로 출퇴근 기록 그룹화
  void _groupAttendancesByStaff() {
    _groupedByStaff = {};

    for (final attendance in _allAttendances) {
      final staff = attendance['staff'] as Map<String, dynamic>?;
      final staffId = staff?['id'] as String? ?? '';

      if (staffId.isEmpty) continue;

      if (!_groupedByStaff.containsKey(staffId)) {
        _groupedByStaff[staffId] = [];
      }
      _groupedByStaff[staffId]!.add(attendance);
    }

    // 각 담당자의 기록을 시간순으로 정렬 (최신이 먼저)
    for (final staffId in _groupedByStaff.keys) {
      _groupedByStaff[staffId]!.sort((a, b) {
        final aTime = a['createdAt'] as String? ?? '';
        final bTime = b['createdAt'] as String? ?? '';
        return bTime.compareTo(aTime);
      });
    }
  }

  /// 오늘 날짜인지 확인
  bool _isToday(String? dateTimeStr) {
    if (dateTimeStr == null) return false;
    try {
      final dateTime = DateTime.parse(dateTimeStr).toLocal();
      final now = DateTime.now();
      return dateTime.year == now.year &&
          dateTime.month == now.month &&
          dateTime.day == now.day;
    } catch (e) {
      return false;
    }
  }

  /// 담당자의 오늘 출근 상태 가져오기
  /// 반환: 'CHECK_IN' (출근), 'CHECK_OUT' (퇴근), 'NOT_CHECKED' (미출근)
  String _getTodayStatus(String staffId) {
    final records = _groupedByStaff[staffId] ?? [];

    // 오늘 기록만 필터링
    final todayRecords = records.where((r) => _isToday(r['createdAt'] as String?)).toList();

    if (todayRecords.isEmpty) {
      return 'NOT_CHECKED';
    }

    // 가장 최신 기록의 타입 반환
    return todayRecords.first['type'] as String? ?? 'NOT_CHECKED';
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
          '담당자 출근 / 퇴근 목록',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorView()
              : _allStaffs.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _allStaffs.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final staff = _allStaffs[index];
                          final staffId = staff['id'] as String? ?? '';
                          final allRecords = _groupedByStaff[staffId] ?? [];
                          final todayStatus = _getTodayStatus(staffId);

                          return _buildStaffCard(
                            staff,
                            todayStatus: todayStatus,
                            allRecords: allRecords,
                          );
                        },
                      ),
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
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF006FFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '다시 시도',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              '등록된 담당자가 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '담당자를 등록하면\n여기에 표시됩니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                color: Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaffCard(
    Map<String, dynamic> staff, {
    required String todayStatus,
    required List<Map<String, dynamic>> allRecords,
  }) {
    final staffName = staff['name'] ?? '알 수 없음';
    final staffCode = staff['staffCode'] ?? '';

    // 상태에 따른 스타일
    String typeText;
    Color typeColor;
    Color typeBgColor;

    switch (todayStatus) {
      case 'CHECK_IN':
        typeText = '출근';
        typeColor = const Color(0xFF10B981);
        typeBgColor = const Color(0xFFECFDF5);
        break;
      case 'CHECK_OUT':
        typeText = '퇴근';
        typeColor = const Color(0xFFEF4444);
        typeBgColor = const Color(0xFFFEF2F2);
        break;
      default: // NOT_CHECKED
        typeText = '미출근';
        typeColor = const Color(0xFF9CA3AF);
        typeBgColor = const Color(0xFFF3F4F6);
    }

    return GestureDetector(
      onTap: () => _showAttendanceHistory(staffName, staffCode, allRecords),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE8EEF2),
            width: 1,
          ),
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
            // 프로필 아이콘
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF2F8FC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person_outline,
                size: 24,
                color: Color(0xFF006FFF),
              ),
            ),
            const SizedBox(width: 12),
            // 담당자 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffName,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    staffCode,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            // 출근/퇴근/미출근 뱃지
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: typeBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                typeText,
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: typeColor,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // 화살표 아이콘
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }

  /// 담당자의 전체 출퇴근 기록 바텀시트
  void _showAttendanceHistory(
    String staffName,
    String staffCode,
    List<Map<String, dynamic>> records,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // 드래그 핸들
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEF2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // 헤더
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8FC),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 24,
                        color: Color(0xFF006FFF),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staffName,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              color: Color(0xFF17191A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            staffCode,
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w400,
                              fontSize: 12,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Color(0xFF464A4D)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8EEF2)),
              // 출퇴근 기록 제목
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  children: [
                    const Text(
                      '출퇴근 기록',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Color(0xFF17191A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8FC),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${records.length}건',
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: Color(0xFF006FFF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 기록 리스트
              Expanded(
                child: records.isEmpty
                    ? const Center(
                        child: Text(
                          '출퇴근 기록이 없습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: records.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          return _buildHistoryItem(records[index]);
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 출퇴근 기록 아이템
  Widget _buildHistoryItem(Map<String, dynamic> record) {
    final type = record['type'] as String? ?? '';
    final createdAt = record['createdAt'] as String?;

    final isCheckIn = type == 'CHECK_IN';
    final typeText = isCheckIn ? '출근' : '퇴근';
    final typeColor = isCheckIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final typeBgColor = isCheckIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final typeIcon = isCheckIn ? Icons.login : Icons.logout;

    String formattedTime = '';
    String formattedDate = '';
    if (createdAt != null) {
      try {
        final dateTime = DateTime.parse(createdAt).toLocal();
        formattedTime = DateFormat('HH:mm').format(dateTime);
        formattedDate = DateFormat('yyyy.MM.dd (E)', 'ko').format(dateTime);
      } catch (e) {
        formattedTime = '';
        formattedDate = '';
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // 아이콘
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeBgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              typeIcon,
              size: 18,
              color: typeColor,
            ),
          ),
          const SizedBox(width: 12),
          // 날짜 정보
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF17191A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formattedTime,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          // 출근/퇴근 뱃지
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: typeBgColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              typeText,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: typeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

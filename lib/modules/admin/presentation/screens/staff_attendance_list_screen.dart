import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:building_manage_front/modules/admin/data/datasources/attendance_alert_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';

class StaffAttendanceListScreen extends ConsumerStatefulWidget {
  const StaffAttendanceListScreen({super.key});

  @override
  ConsumerState<StaffAttendanceListScreen> createState() => _StaffAttendanceListScreenState();
}

class _StaffAttendanceListScreenState extends ConsumerState<StaffAttendanceListScreen> {
  List<Map<String, dynamic>> _allAttendances = [];
  Map<String, List<Map<String, dynamic>>> _groupedByStaff = {};
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAttendances();
  }

  Future<void> _loadAttendances() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dataSource = ref.read(attendanceAlertRemoteDataSourceProvider);
      final response = await dataSource.getDashboardAlerts();

      if (response['success'] == true) {
        final data = response['data'] as Map<String, dynamic>;
        final latestAttendances = data['latestAttendances'] as List<dynamic>? ?? [];

        setState(() {
          _allAttendances = latestAttendances.cast<Map<String, dynamic>>();
          _groupAttendancesByStaff();
        });
      }
    } catch (e) {
      setState(() {
        if (e is ApiException) {
          _errorMessage = e.userFriendlyMessage;
        } else {
          _errorMessage = '출퇴근 목록을 불러오는 중 오류가 발생했습니다.';
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

  /// 담당자별 최신 출퇴근 기록 목록 가져오기
  List<Map<String, dynamic>> _getLatestPerStaff() {
    final result = <Map<String, dynamic>>[];

    for (final entry in _groupedByStaff.entries) {
      if (entry.value.isNotEmpty) {
        result.add(entry.value.first); // 가장 최신 기록
      }
    }

    // 최신순으로 정렬
    result.sort((a, b) {
      final aTime = a['createdAt'] as String? ?? '';
      final bTime = b['createdAt'] as String? ?? '';
      return bTime.compareTo(aTime);
    });

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final latestPerStaff = _getLatestPerStaff();

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
              : latestPerStaff.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadAttendances,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: latestPerStaff.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final attendance = latestPerStaff[index];
                          final staff = attendance['staff'] as Map<String, dynamic>?;
                          final staffId = staff?['id'] as String? ?? '';
                          final allRecords = _groupedByStaff[staffId] ?? [];

                          return _buildAttendanceCard(
                            attendance,
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
              onPressed: _loadAttendances,
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
              Icons.access_time_outlined,
              size: 64,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            const Text(
              '출퇴근 기록이 없습니다.',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '담당자가 출퇴근 체크를 하면\n여기에 표시됩니다.',
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

  Widget _buildAttendanceCard(
    Map<String, dynamic> attendance, {
    required List<Map<String, dynamic>> allRecords,
  }) {
    final staff = attendance['staff'] as Map<String, dynamic>?;
    final staffName = staff?['name'] ?? '알 수 없음';
    final staffCode = staff?['staffCode'] ?? '';
    final type = attendance['type'] as String? ?? '';

    // 출근/퇴근 타입에 따른 스타일
    final isCheckIn = type == 'CHECK_IN';
    final typeText = isCheckIn ? '출근' : '퇴근';
    final typeColor = isCheckIn ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final typeBgColor = isCheckIn ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);

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
              color: Colors.black.withOpacity(0.04),
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
            // 출근/퇴근 뱃지
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

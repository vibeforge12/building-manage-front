import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/manager/presentation/providers/attendance_provider.dart';
import 'package:building_manage_front/modules/manager/data/datasources/staff_complaints_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/confirmation_dialog.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen> {
  int _tabIndex = 0; // 0: 민원 관리, 1: 공지사항
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoadingComplaints = false;
  List<Map<String, dynamic>> _pendingComplaints = [];
  String? _complaintsError;
  bool _isLoadingNotices = false;
  List<Map<String, dynamic>> _notices = [];
  String? _noticesError;

  @override
  void initState() {
    super.initState();
    _loadPendingComplaints();
    _loadNotices();
  }

  Future<void> _loadPendingComplaints() async {
    setState(() {
      _isLoadingComplaints = true;
      _complaintsError = null;
    });

    try {
      final dataSource = ref.read(staffComplaintsRemoteDataSourceProvider);
      final response = await dataSource.getPendingComplaintsHighlight();

      if (response['success'] == true && response['data'] != null) {
        setState(() {
          _pendingComplaints = List<Map<String, dynamic>>.from(response['data'] ?? []);
          _isLoadingComplaints = false;
        });
      } else {
        setState(() {
          _complaintsError = '민원을 불러올 수 없습니다.';
          _isLoadingComplaints = false;
        });
      }
    } catch (e) {
      print('❌ 미완료 민원 조회 실패: $e');
      setState(() {
        _complaintsError = '민원 로드 중 오류가 발생했습니다.';
        _isLoadingComplaints = false;
      });
    }
  }

  Future<void> _loadNotices() async {
    setState(() {
      _isLoadingNotices = true;
      _noticesError = null;
    });

    try {
      final dataSource = ref.read(staffComplaintsRemoteDataSourceProvider);
      final response = await dataSource.getStaffNotices(limit: 3);

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>?;
        setState(() {
          _notices = items?.map((item) => item as Map<String, dynamic>).toList() ?? [];
          _isLoadingNotices = false;
        });
      } else {
        setState(() {
          _noticesError = '공지사항을 불러올 수 없습니다.';
          _isLoadingNotices = false;
        });
      }
    } catch (e) {
      print('❌ 공지사항 조회 실패: $e');
      setState(() {
        _noticesError = '공지사항 로드 중 오류가 발생했습니다.';
        _isLoadingNotices = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(''),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          )
        ],
      ),
      endDrawer: _buildMenuDrawer(context),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Container(
              color: const Color(0xFFEFF6FF),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  Center(
                    child: Column(
                      children: [
                        Icon(Icons.camera_alt_outlined, size: 48, color: theme.colorScheme.primary.withOpacity(0.6)),
                        const SizedBox(height: 8),
                        Text('Placeholder', style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary.withOpacity(0.6))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Text(
                  //   '담당자님\n안녕하세요:)',
                  //   style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  // ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleCheckIn(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF006FFF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        '출근',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleCheckOut(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFFEAF2FF),
                        foregroundColor: const Color(0xFF0A66FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text(
                        '퇴근',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                      ),),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: Divider(height: 10)),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: _DashboardTabs(
                    index: _tabIndex,
                    onChanged: (i) => setState(() => _tabIndex = i),
                  ),
                ),
                if (_tabIndex == 0) ...[
                  if (_isLoadingComplaints)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_complaintsError != null)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          _complaintsError!,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF757B80),
                          ),
                        ),
                      ),
                    )
                  else if (_pendingComplaints.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          '미완료 민원이 없습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF757B80),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._pendingComplaints.map((complaint) {
                      final complaintId = complaint['id'] as String?;
                      final title = complaint['title'] as String? ?? '제목없음';
                      final resident = complaint['resident'] as Map<String, dynamic>?;
                      final residentName = resident?['name'] as String? ?? '거주자명';
                      final dong = resident?['dong'] as String? ?? '';
                      final hosu = resident?['hosu'] as String? ?? '';
                      final subtitle = '${dong}동 $hosu호 $residentName'.trim();

                      return _ComplaintTile(
                        complaintId: complaintId,
                        title: title,
                        subtitle: subtitle,
                      );
                    }),
                ] else ...[
                  if (_isLoadingNotices)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_noticesError != null)
                    Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          _noticesError!,
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF757B80),
                          ),
                        ),
                      ),
                    )
                  else if (_notices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Center(
                        child: Text(
                          '공지사항이 없습니다.',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 14,
                            color: Color(0xFF757B80),
                          ),
                        ),
                      ),
                    )
                  else
                    ..._notices.map((notice) {
                      final noticeId = notice['id'] as String?;
                      final title = notice['title'] as String? ?? '제목없음';
                      final createdAt = notice['createdAt'] as String?;

                      // Format date: extract just the date part from ISO string
                      String formattedDate = '';
                      if (createdAt != null) {
                        try {
                          final dateTime = DateTime.parse(createdAt);
                          formattedDate = '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
                        } catch (e) {
                          formattedDate = '';
                        }
                      }

                      return _NoticeTile(
                        noticeId: noticeId,
                        title: title,
                        subtitle: formattedDate,
                      );
                    }),
                ],
              ],
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Future<void> _handleCheckIn(BuildContext context) async {
    print('🔵 _handleCheckIn 시작');
    final attendanceState = ref.read(attendanceProvider);
    print('🔵 현재 상태: ${attendanceState.status}');
    print('🔵 isCheckedIn: ${attendanceState.isCheckedIn}');
    print('🔵 isCheckedOut: ${attendanceState.isCheckedOut}');

    // 이미 퇴근한 경우 (출근과 퇴근을 모두 완료한 경우)
    if (attendanceState.isCheckedOut) {
      print('🔴 이미 퇴근한 상태');
      await InfoDialog.show(
        context,
        title: '이미 퇴근 하셨습니다',
        content: '금일 근무가 완료되었습니다.',
      );
      return;
    }

    // 이미 출근한 경우
    if (attendanceState.isCheckedIn) {
      print('🔴 이미 출근한 상태');
      await InfoDialog.show(
        context,
        title: '이미 출근하셨습니다',
        content: '출근 처리가 완료되었습니다.',
      );
      return;
    }

    // 출근 확인 다이얼로그
    print('🟢 다이얼로그 표시');
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '출근 등록 하시겠습니까?',
      content: '(한번 등록하면 재출근 처리가 불가 합니다)',
    );

    print('🟢 다이얼로그 결과: $confirmed');

    if (!confirmed || !context.mounted) return;

    // Provider를 통한 출근 처리
    print('🟢 출근 처리 API 호출');
    final success = await ref.read(attendanceProvider.notifier).checkIn();
    print('🟢 출근 처리 결과: $success');

    if (!context.mounted) return;

    if (success) {
      print('✅ 출근 성공');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('출근이 등록되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('❌ 출근 실패');
      // 상태를 다시 읽어서 서버 동기화 여부 확인
      final updatedState = ref.read(attendanceProvider);
      final error = updatedState.error;

      // 서버에서 "이미 출근"이라고 응답하여 상태가 동기화된 경우
      if (updatedState.isCheckedIn && error?.contains('이미 출근') == true) {
        print('🔄 서버 상태 동기화 완료 - InfoDialog 표시');
        await InfoDialog.show(
          context,
          title: '이미 출근하셨습니다',
          content: '출근 처리가 완료되었습니다.',
        );
      } else {
        // 일반 에러의 경우 SnackBar 표시
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? '출근 처리 중 오류가 발생했습니다.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _handleCheckOut(BuildContext context) async {
    print('🔵 _handleCheckOut 시작');
    final attendanceState = ref.read(attendanceProvider);
    print('🔵 현재 상태: ${attendanceState.status}');
    print('🔵 isCheckedIn: ${attendanceState.isCheckedIn}');
    print('🔵 isCheckedOut: ${attendanceState.isCheckedOut}');

    // 이미 퇴근한 경우
    if (attendanceState.isCheckedOut) {
      print('🔴 이미 퇴근한 상태');
      await InfoDialog.show(
        context,
        title: '이미 퇴근하였습니다',
        content: '퇴근 처리가 완료되었습니다.',
      );
      return;
    }

    // 출근하지 않은 경우
    if (!attendanceState.isCheckedIn) {
      print('🔴 출근하지 않은 상태');
      await InfoDialog.show(
        context,
        title: '출근하지 않았습니다',
        content: '출근 처리 후 퇴근이 가능합니다.',
      );
      return;
    }

    // 퇴근 확인 다이얼로그
    print('🟢 퇴근 다이얼로그 표시');
    final confirmed = await ConfirmationDialog.show(
      context,
      title: '퇴근 하시겠습니까?',
      content: '(퇴근 처리하면 더이상 처리가 안됩니다)',
    );

    print('🟢 퇴근 다이얼로그 결과: $confirmed');

    if (!confirmed || !context.mounted) return;

    // Provider를 통한 퇴근 처리
    print('🟢 퇴근 처리 API 호출');
    final success = await ref.read(attendanceProvider.notifier).checkOut();
    print('🟢 퇴근 처리 결과: $success');

    if (!context.mounted) return;

    if (success) {
      print('✅ 퇴근 성공');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('퇴근이 등록되었습니다.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      print('❌ 퇴근 실패');
      final error = ref.read(attendanceProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? '퇴근 처리 중 오류가 발생했습니다.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildMenuDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      width: MediaQuery.of(context).size.width,
      child: SafeArea(
        child: Column(
          children: [
            // Navigation Bar
            Container(
              height: 48,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFE8EEF2),
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  // Back button
                  Positioned(
                    left: 0,
                    top: 0,
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Color(0xFF464A4D),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  // Title
                  const Center(
                    child: Text(
                      '더보기',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.5,
                        color: Color(0xFF464A4D),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Profile Section
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Profile Image
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 32,
                      color: Color(0xFF006FFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Name and Phone
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final currentUser = ref.watch(currentUserProvider);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? '테스트명',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 16,
                                height: 1.5,
                                color: Color(0xFF17191A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentUser?.phoneNumber ?? '010-0000-0000',
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.67,
                                color: Color(0xFF757B80),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Spacer
            Container(
              height: 8,
              color: const Color(0xFFF2F8FC),
            ),

            // Menu List
            Column(
              children: [
                _buildMenuItem(
                  title: '민원 관리',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to complaint management
                  },
                ),
                _buildMenuItem(
                  title: '출근 / 퇴근 조회',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/manager/attendance-history');
                  },
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFE8EEF2),
                ),
                _buildMenuItem(
                  title: '로그아웃',
                  onTap: () async {
                    Navigator.pop(context);

                    // 로그아웃 처리
                    await ref.read(authStateProvider.notifier).logout();

                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  height: 1.5,
                  color: Color(0xFF17191A),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 24,
              color: Color(0xFF464A4D),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String text;
  final bool selected;
  const _TabChip({required this.text, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.titleMedium?.copyWith(
              color: selected ? Colors.black : theme.colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: selected ? Colors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _ComplaintTile extends StatelessWidget {
  final String? complaintId;
  final String title;
  final String subtitle;
  const _ComplaintTile({
    required this.complaintId,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (complaintId != null) {
            context.push('/manager/complaint-detail/$complaintId');
          }
        },
      ),
    );
  }
}

class _NoticeTile extends StatelessWidget {
  final String? noticeId;
  final String title;
  final String subtitle;
  const _NoticeTile({
    this.noticeId,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          // TODO: Navigate to notice detail screen when available
          // if (noticeId != null) {
          //   context.push('/manager/notice-detail/$noticeId');
          // }
        },
      ),
    );
  }
}

class _DashboardTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  const _DashboardTabs({required this.index, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(0),
          behavior: HitTestBehavior.opaque,
          child: _TabChip(text: '민원 관리', selected: index == 0),
        ),
        const SizedBox(width: 16),
        GestureDetector(
          onTap: () => onChanged(1),
          behavior: HitTestBehavior.opaque,
          child: _TabChip(text: '공지사항', selected: index == 1),
        ),
        const Spacer(),
        TextButton(onPressed: () {}, child: const Text('전체보기')),
      ],
    );
  }
}

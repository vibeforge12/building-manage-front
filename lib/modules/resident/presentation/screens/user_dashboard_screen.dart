import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:building_manage_front/modules/resident/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/confirmation_dialog.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

import '../../../../shared/widgets/custom_confirmation_dialog.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _departments = [];
  List<Map<String, dynamic>> _notices = [];
  List<Map<String, dynamic>> _events = [];
  bool _isLoadingDepartments = true;
  bool _isLoadingContent = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // 부서별 아이콘 매핑
  final Map<String, String> _departmentIcons = {
    '미화': 'assets/icons/deco_filled.svg',
    '소방': 'assets/icons/flame_filled.svg',
    '방제': 'assets/icons/warning_filled.svg',
    '관리': 'assets/icons/calendar_check_filled.svg',
    '기계': 'assets/icons/settings_filled.svg',
    '전기': 'assets/icons/lightning_filled.svg',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadDepartments();
    _loadNotices();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (_tabController.index == 0) {
      _loadNotices();
    } else {
      _loadEvents();
    }
  }

  Future<void> _loadDepartments() async {
    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      // 공통 부서 API로 전체 부서 목록 가져오기
      final departmentDataSource = ref.read(departmentRemoteDataSourceProvider);
      final response = await departmentDataSource.getDepartments(
        limit: 100,
        status: 'ACTIVE',
      );

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _departments = List<Map<String, dynamic>>.from(data['items'] ?? []);
        });
      }
    } catch (e) {
      print('부서 목록 조회 실패: $e');
    } finally {
      setState(() {
        _isLoadingDepartments = false;
      });
    }
  }

  Future<void> _loadNotices() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getNoticeHighlights();

      if (response['success'] == true) {
        setState(() {
          _notices = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      }
    } catch (e) {
      print('공지사 조회 실패: $e');
      setState(() {
        _notices = [];
      });
    } finally {
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoadingContent = true;
    });

    try {
      final noticeDataSource = ref.read(noticeRemoteDataSourceProvider);
      final response = await noticeDataSource.getEventHighlights();

      if (response['success'] == true) {
        setState(() {
          _events = List<Map<String, dynamic>>.from(response['data'] ?? []);
        });
      }
    } catch (e) {
      print('이벤트 조회 실패: $e');
      setState(() {
        _events = [];
      });
    } finally {
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  String _getTimeAgo(String? createdAt) {
    if (createdAt == null) return '';

    try {
      final dateTime = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}분 전';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}시간 전';
      } else if (difference.inDays < 30) {
        return '${dateTime.month}월 ${dateTime.day}일';
      } else {
        return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일';
      }
    } catch (e) {
      return '';
    }
  }

  String _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '';

    // 숫자만 추출
    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return phoneNumber;

    // 010-1234-5678 형식으로 포맷팅
    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    return phoneNumber;
  }

  @override
  Widget build(BuildContext context) {
    final currentItems = _tabController.index == 0 ? _notices : _events;
    final currentUser = ref.watch(currentUserProvider);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildDrawerMenu(),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 네비게이션 바
            _buildTopBar(),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 배경 이미지 영역
                    _buildHeaderImage(),

                    // 건물명 (위 패딩 추가)
                    Padding(
                      padding: const EdgeInsets.only(top: 24, left: 16, right: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          currentUser?.buildingName ?? '-',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 36,
                            color: Color(0xFF17191A),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 민원 등록 섹션
                    _buildDepartmentSection(),

                    const SizedBox(height: 16),
                    // 구분선 + 공지사항/이벤트 탭 + 전체보기 버튼
                    _buildDividerAndTabSection(),

                    // 공지사항/이벤트 리스트
                    Stack(
                      children: [
                        // 데이터가 있으면 항상 표시 (로딩 중에도 유지)
                        if (currentItems.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: currentItems.length > 5 ? 5 : currentItems.length,
                            itemBuilder: (context, index) {
                              final item = currentItems[index];
                              final isNotice = _tabController.index == 0;
                              return _buildNoticeItem(
                                item['title'] ?? '',
                                _getTimeAgo(item['createdAt']),
                                noticeId: isNotice ? item['id'] as String? : null,
                                eventId: !isNotice ? item['id'] as String? : null,
                                routeName: isNotice ? 'userNoticeDetail' : 'userEventDetail',
                              );
                            },
                          ),

                        // 로딩 중 또는 비어있을 때만 표시
                        if (_isLoadingContent || currentItems.isEmpty)
                          Container(
                            color: _isLoadingContent ? Colors.transparent : Colors.white,
                            child: _isLoadingContent
                                ? Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Center(
                                      child: SizedBox(
                                        width: 40,
                                        height: 40,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            const Color(0xFF006FFF).withOpacity(0.7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Center(
                                      child: Text(
                                        _tabController.index == 0
                                            ? '공지사항이 없습니다.'
                                            : '이벤트가 없습니다.',
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14,
                                          color: Color(0xFF757B80),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EEF2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, size: 24),
                onPressed: () {
                  // TODO: 알림 화면으로 이동
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Color(0xFF006FFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '2',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.menu, size: 24),
            onPressed: () {
              _showProfileMenu();
            },
          ),
        ],
      ),
    );
  }

  void _showProfileMenu() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  Widget _buildDrawerMenu() {
    final currentUser = ref.read(currentUserProvider);

    return Drawer(
      width: double.infinity,
      shape: const RoundedRectangleBorder(),
      child: Container(
        color: Colors.white,
        child: SafeArea(
          top: true,
          bottom: false,
          left: false,
          right: false,
          child: Column(
            children: [
              // 상단 네비게이션 바
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
                child: Row(
                  children: [
                    const SizedBox(width: 48),
                    const Expanded(
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          '더보기',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Color(0xFF17191A),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 24),
                      onPressed: () => Navigator.pop(context),
                      padding: const EdgeInsets.all(12),
                    ),
                  ],
                ),
              ),
            // 프로필 섹션 (위 패딩 추가)
            Padding(
              padding: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
              child: Row(
                children: [
                  // 프로필 이미지 (placeholder)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF2F8FC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF006FFF),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // 사용자 정보
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser?.name ?? '사용자명',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 16,
                            color: Color(0xFF17191A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatPhoneNumber(currentUser?.phoneNumber),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w400,
                            fontSize: 12,
                            color: Color(0xFF757B80),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 구분선 (8px 높이)
            Container(
              height: 8,
              color: const Color(0xFFF2F8FC),
            ),
            // 구분선 (1px)
            Container(
              height: 1,
              color: const Color(0xFFE8EEF2),
            ),
            // 메뉴 아이템 1: 내 정보
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed('userProfile');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '내 정보',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF757B80),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 메뉴 아이템 2: 내 민원 보기
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  context.pushNamed('myComplaints');
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '내 민원 보기',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF757B80),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 메뉴 아이템 3: 알림함
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: 알림함 화면으로 이동
                  Navigator.pop(context);
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '알림함',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Color(0xFF757B80),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // 메뉴 아이템 4: 로그아웃
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  // 로그아웃 처리
                  final authStateNotifier = ref.read(authStateProvider.notifier);
                  await authStateNotifier.logout();
                  if (mounted) {
                    context.go('/');
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '로그아웃',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Color(0xFF17191A),
                        ),
                      ),
                      const Icon(
                        Icons.logout,
                        size: 16,
                        color: Color(0xFF757B80),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    final currentUser = ref.watch(currentUserProvider);
    final buildingImageUrl = currentUser?.buildingImageUrl;

    return Container(
      width: double.infinity,
      height: 338,
      child: buildingImageUrl != null && buildingImageUrl.isNotEmpty
          ? CachedNetworkImage(
              imageUrl: buildingImageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFE3F2FD),
                      Colors.white.withValues(alpha: 0.5),
                    ],
                  ),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006FFF)),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Image.asset(
                'assets/home.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: 338,
              ),
            )
          : Image.asset(
              'assets/home.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 338,
            ),
    );
  }

  Widget _buildDepartmentSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '민원등록',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 20,
              color: Color(0xFF17191A),
            ),
          ),
          const SizedBox(height: 16),
          _isLoadingDepartments
              ? const Center(child: CircularProgressIndicator())
              : _buildDepartmentGrid(),
        ],
      ),
    );
  }

  Widget _buildDepartmentGrid() {
    // 모든 부서를 3개씩 행으로 표시 (동적으로 계속 생성)
    List<Widget> rows = [];

    for (int i = 0; i < _departments.length; i += 3) {
      List<Widget> rowChildren = [];

      // 첫 번째 부서
      rowChildren.add(Expanded(child: _buildDepartmentCard(_departments[i])));

      // 두 번째 부서 (있으면)
      if (i + 1 < _departments.length) {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(Expanded(child: _buildDepartmentCard(_departments[i + 1])));
      } else {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      // 세 번째 부서 (있으면)
      if (i + 2 < _departments.length) {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(Expanded(child: _buildDepartmentCard(_departments[i + 2])));
      } else {
        rowChildren.add(const SizedBox(width: 8));
        rowChildren.add(const Expanded(child: SizedBox()));
      }

      rows.add(
        Row(children: rowChildren),
      );

      // 다음 행과의 간격
      if (i + 3 < _departments.length) {
        rows.add(const SizedBox(height: 8));
      }
    }

    return Column(children: rows);
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department) {
    final deptName = department['name'] as String;
    final deptId = department['id'] as String;
    final iconPath = _departmentIcons[deptName];
    final currentUser = ref.read(currentUserProvider);

    return InkWell(
      onTap: () async {
        // 1️⃣ 먼저 사용자 승인 상태 확인
        final approvalStatus = currentUser?.approvalStatus;

        // PENDING 상태: 회원가입 승인 대기 중
        if (approvalStatus == 'PENDING') {
          if (mounted) {
            await showCustomConfirmationDialog(
              context: context,
              title: '',
              content: Text(
                '회원가입 승인 대기중 입니다.',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              confirmText: '확인',
              cancelText: '',
              barrierDismissible: false,
              confirmOnLeft: true,
            );
          }
          return;
        }

        // REJECTED 상태: 승인 거부
        if (approvalStatus == 'REJECTED') {
          if (mounted) {
            await InfoDialog.show(
              context,
              title: '승인 거부',
              content: '아직 승인되지 않았습니다.',
            );
          }
          return;
        }

        // APPROVED 상태만 진행: 부서의 담당자 배정 여부 확인
        if (approvalStatus == 'APPROVED') {
          try {
            final residentDeptDataSource = ref.read(residentDepartmentRemoteDataSourceProvider);
            final response = await residentDeptDataSource.getDepartments();

            if (response['success'] == true) {
              final userDepartments = List<Map<String, dynamic>>.from(response['data'] ?? []);

              // 현재 부서의 isActive 찾기
              final matchedDept = userDepartments.firstWhere(
                (dept) => dept['id'] == deptId,
                orElse: () => {'isActive': false},
              );

              final isActive = matchedDept['isActive'] as bool? ?? false;

              // 담당자가 없는 부서인 경우 팝업 표시
              if (!isActive) {
                if (mounted) {
                  if (mounted) {
                    await showCustomConfirmationDialog(
                      context: context,
                      title: '',
                      content: Text(
                        '해당 부서의 담당자가 배정되지 않았습니다.',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      confirmText: '확인',
                      cancelText: '',
                      barrierDismissible: false,
                      confirmOnLeft: true,
                    );
                  }
                }
                return;
              }

              // 담당자가 있는 경우 민원 등록 화면으로 이동
              if (mounted) {
                context.pushNamed(
                  'complaintCreate',
                  queryParameters: {
                    'departmentId': deptId,
                    'departmentName': deptName,
                  },
                );
              }
            }
          } catch (e) {
            print('부서 상태 확인 실패: $e');
          }
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
            color: const Color(0xFFE8EEF2),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconPath != null)
              SvgPicture.asset(
                iconPath,
                width: 24,
                height: 24,
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF006FFF),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(height: 8),
            Text(
              deptName,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF17191A),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDividerAndTabSection() {
    return Column(
      children: [
        // 구분선
        Container(
          height: 8,
          color: const Color(0xFFF2F8FC),
        ),
        // 공지사항/이벤트 탭 + 전체보기 버튼
        _buildTabAndViewAllSection(),
      ],
    );
  }

  Widget _buildTabAndViewAllSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16), // 기존 패딩 유지
      child: Container(
        // 회색 밑줄 전체(좌우 패딩 안쪽 전체 폭) 적용
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Color(0xFFE2E5E7), // 회색 라인
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // TabBar는 왼쪽 + 남은 공간 전부 차지
            Expanded(
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelPadding: const EdgeInsets.only(right: 12),
                indicatorSize: TabBarIndicatorSize.label,

                labelStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
                labelColor: const Color(0xFF17191A),
                unselectedLabelColor: Color(0xFF17191A).withOpacity(0.5),

                // TabBar 기본 divider 제거(회색선 중복 제거)
                dividerColor: Colors.transparent,

                // 검정 인디케이터 = 라운드 없음
                indicator: const UnderlineTabIndicator(
                  borderSide: BorderSide(
                    width: 3,
                    color: Color(0xFF17191A),
                  ),
                  insets: EdgeInsets.zero,
                ),

                tabs: const [
                  Tab(text: '공지사항'),
                  Tab(text: '이벤트'),
                ],
              ),
            ),

            // 오른쪽 끝에 전체보기 (공지사항 아이템 패딩과 동일하게 정렬)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  '전체보기',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF757B80),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildNoticeItem(String title, String time, {String? noticeId, String? eventId, String? routeName}) {
    return InkWell(
      onTap: (noticeId != null || eventId != null)
          ? () {
              final id = noticeId ?? eventId;
              final route = routeName ?? 'userNoticeDetail';
              context.pushNamed(
                route,
                pathParameters: {
                  noticeId != null ? 'noticeId' : 'eventId': id!,
                },
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  fontSize: 14,
                  color: Color(0xFF464A4D),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              time,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF17191A),
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }

}

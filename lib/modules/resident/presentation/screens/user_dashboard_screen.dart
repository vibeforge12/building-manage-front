import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/resident/data/datasources/notice_remote_datasource.dart';
import 'package:building_manage_front/modules/resident/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/modules/headquarters/data/datasources/department_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/custom_dialog.dart';

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
      print('공지사항 조회 실패: $e');
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

  @override
  Widget build(BuildContext context) {
    final currentItems = _tabController.index == 0 ? _notices : _events;

    return Scaffold(
      backgroundColor: Colors.white,
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

                    // 건물명
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '건물명',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 36,
                            color: Color(0xFF17191A),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // 민원 등록 섹션
                    _buildDepartmentSection(),

                    const SizedBox(height: 16),

                    // 구분선
                    Container(
                      height: 8,
                      color: const Color(0xFFF2F8FC),
                    ),

                    // 공지사항/이벤트 탭
                    _buildTabSection(),

                    // 전체보기 버튼
                    Padding(
                      padding: const EdgeInsets.only(right: 16, top: 8),
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // TODO: 전체보기 화면으로 이동
                          },
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
                    ),

                    // 공지사항/이벤트 리스트
                    _isLoadingContent
                        ? const Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        : currentItems.isEmpty
                            ? Padding(
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
                              )
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: currentItems.length > 5 ? 5 : currentItems.length,
                                itemBuilder: (context, index) {
                                  final item = currentItems[index];
                                  return _buildNoticeItem(
                                    item['title'] ?? '',
                                    _getTimeAgo(item['createdAt']),
                                  );
                                },
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
              // TODO: 메뉴 열기
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Container(
      width: double.infinity,
      height: 338,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFE3F2FD),
            Colors.white.withOpacity(0.5),
          ],
        ),
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
    // 모든 부서를 표시 (필터링 제거)
    return Column(
      children: [
        Row(
          children: [
            if (_departments.isNotEmpty)
              Expanded(child: _buildDepartmentCard(_departments[0])),
            if (_departments.length > 1) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildDepartmentCard(_departments[1])),
            ],
            if (_departments.length > 2) ...[
              const SizedBox(width: 8),
              Expanded(child: _buildDepartmentCard(_departments[2])),
            ],
          ],
        ),
        if (_departments.length > 3) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildDepartmentCard(_departments[3])),
              if (_departments.length > 4) ...[
                const SizedBox(width: 8),
                Expanded(child: _buildDepartmentCard(_departments[4])),
              ],
              if (_departments.length > 5) ...[
                const SizedBox(width: 8),
                Expanded(child: _buildDepartmentCard(_departments[5])),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDepartmentCard(Map<String, dynamic> department) {
    final deptName = department['name'] as String;
    final deptId = department['id'] as String;
    final iconPath = _departmentIcons[deptName];

    return InkWell(
      onTap: () async {
        // 유저 부서 API로 isActive 확인
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
                showDialog(
                  context: context,
                  builder: (context) => const CustomDialog(
                    title: '담당자 미배정',
                    message: '해당 담당자는 아직 배정되지 않았습니다.',
                  ),
                );
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

  Widget _buildTabSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelPadding: const EdgeInsets.only(right: 32, top: 16, bottom: 16),
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
              unselectedLabelColor: const Color(0xFF17191A).withOpacity(0.5),
              indicatorColor: const Color(0xFF17191A),
              tabs: const [
                Tab(text: '공지사항'),
                Tab(text: '이벤트'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String title, String time) {
    return Container(
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
          SizedBox(
            width: 49,
            child: Text(
              time,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 12,
                color: Color(0xFF17191A),
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}

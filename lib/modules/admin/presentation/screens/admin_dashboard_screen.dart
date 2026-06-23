import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:building_manage_front/shared/widgets/separator.dart';
import 'package:building_manage_front/shared/widgets/common_navigation_bar.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/admin/presentation/providers/admin_providers.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 활성화될 때 NEW 뱃지 상태 갱신
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent) {
      ref.invalidate(hasPendingResidentsProvider);
      ref.invalidate(hasPendingComplaintsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: _buildMenuDrawer(context),
      body: SafeArea(
        child: Column(
          children: [
            // Navigation Bar - white background at top
            CommonNavigationBar(
              notificationCount: 2,
              onNotificationTap: () {
                // Handle notification tap
              },
              onMenuTap: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),

            // Scrollable content below navigation bar
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with background image
                    _buildHeader(),

                    // Account issuance button
                    _buildAccountIssuanceButton(context),

                    const SizedBox(height: 30),
                    const SeparatorWidget(),

                    // Menu grid
                    _buildMenuGrid(context),

                    _buildFixedBottomButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final currentUser = ref.watch(currentUserProvider);
    final buildingImageUrl = currentUser?.buildingImageUrl;

    return SizedBox(
      height: 344,
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
                height: 344,
              ),
            )
          : Image.asset(
              'assets/home.png',
              fit: BoxFit.cover,
              width: double.infinity,
              height: 344,
            ),
    );
  }


  Widget _buildMenuGrid(BuildContext context) {
    // 신규 입주민 존재 여부 확인
    final hasPendingResidents = ref.watch(hasPendingResidentsProvider);
    // 신규 민원 존재 여부 확인
    final hasPendingComplaints = ref.watch(hasPendingComplaintsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 16, 0),
      child: Column(
        children: [
          // First row
          Row(
            children: [
              Expanded(
                child: _buildMenuCard(
                  icon: 'assets/icons/users_filled.svg',
                  title: '입주민 관리',
                  showNewBadge: hasPendingResidents.when(
                    data: (hasNew) => hasNew,
                    loading: () => false,
                    error: (_, __) => false,
                  ),
                  onTap: () {
                    context.push('/admin/resident-management');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMenuCard(
                  icon: 'assets/icons/calendar_check_filled.svg',
                  title: '민원 관리',
                  showNewBadge: hasPendingComplaints.when(
                    data: (hasNew) => hasNew,
                    loading: () => false,
                    error: (_, __) => false,
                  ),
                  onTap: () {
                    context.push('/admin/complaint-management');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Second row
          Row(
            children: [
              Expanded(
                child: _buildMenuCard(
                  icon: 'assets/icons/crown_filled.svg',
                  title: '담당자 관리',
                  onTap: () {
                    context.push('/admin/staff-management');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMenuCard(
                  icon: 'assets/icons/notice_filled.svg',
                  title: '공지사항 등록',
                  onTap: () {
                    context.push('/admin/notice-management');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required String icon,
    required String title,
    required VoidCallback onTap,
    bool showNewBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SvgPicture.asset(
                  icon,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF006FFF),
                    BlendMode.srcIn,
                  ),
                ),
                // NEW 배지
                if (showNewBadge)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF17191A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountIssuanceButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 41, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: () {
            context.pushNamed('staffAccountIssuance');
          },
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF006FFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
          ),
          child: const Text(
            '담당자 계정발급',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              fontSize: 16,
              height: 1.5,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFixedBottomButton(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        color: Colors.white,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: () {
              context.push('/admin/staff-attendance-list');
            },
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEDF9FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(16),
            ),
            child: const Text(
              '담당자 출근 / 퇴근 목록',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                height: 1.5,
                color: Color(0xFF0683FF),
              ),
            ),
          ),
        ),
      ),
    );
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
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    currentUser?.name ?? '관리자명',
                                    style: const TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontWeight: FontWeight.w400,
                                      fontSize: 16,
                                      height: 1.5,
                                      color: Color(0xFF17191A),
                                    ),
                                  ),
                                ),
                                if (currentUser?.managerType != null) ...[
                                  const SizedBox(width: 8),
                                  _buildManagerTypeBadge(currentUser!.managerType!),
                                ],
                              ],
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
                  title: '입주민 관리',
                  onTap: () {
                    context.push('/admin/resident-management');
                  },
                ),
                _buildMenuItem(
                  title: '민원 관리',
                  onTap: () {
                    context.push('/admin/complaint-management');
                  },
                ),
                _buildMenuItem(
                  title: '담당자 관리',
                  onTap: () {
                    context.push('/admin/staff-management');
                  },
                ),
                // 일반관리자 추가 (총관리자 전용)
                if (ref.watch(currentUserProvider)?.managerType == 'HEAD')
                  _buildMenuItem(
                    title: '일반관리자 추가',
                    onTap: () {
                      context.push('/manager/add-general-manager');
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
                    // 로그아웃 처리
                    await ref.read(authStateProvider.notifier).logout();

                    if (context.mounted) {
                      context.go('/');
                    }
                  },
                ),
              ],
            ),
            const Spacer(),
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                final version = snapshot.data?.version ?? '';
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Center(
                    child: Text(
                      'v$version',
                      style: const TextStyle(
                        color: Color(0xFFA4ADB2),
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 관리자 종류 뱃지 (총관리자 / 일반관리자)
  Widget _buildManagerTypeBadge(String managerType) {
    final bool isHead = managerType == 'HEAD';
    final Color fg = isHead ? const Color(0xFF006FFF) : const Color(0xFF757B80);
    final Color bg = isHead ? const Color(0xFFEFF5FF) : const Color(0xFFF2F4F6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isHead ? '총관리자' : '일반관리자',
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w600,
          fontSize: 11,
          color: fg,
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

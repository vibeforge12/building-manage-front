import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/shared/widgets/separator.dart';
import 'package:building_manage_front/shared/widgets/common_navigation_bar.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
    return SizedBox(
      height: 344,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/home.png',
              fit: BoxFit.cover,
            ),
          ),

          // Logo (placeholder - you can add actual logo)
          // Positioned(
          //   left: 28,
          //   top: 309,
          //   child: Container(
          //     width: 109,
          //     height: 40,
          //     color: Colors.white.withOpacity(0.2),
          //     // Add your logo widget here
          //   ),
          // ),
          //
          // // Building name text
          // const Positioned(
          //   left: 16,
          //   top: 323,
          //   child: Text(
          //     '건물명',
          //     style: TextStyle(
          //       fontFamily: 'Pretendard',
          //       fontWeight: FontWeight.w700,
          //       fontSize: 36,
          //       height: 1.25,
          //       color: Color(0xFF17191A),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }


  Widget _buildMenuGrid(BuildContext context) {
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
                  onTap: () {
                    // Navigate to resident management
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMenuCard(
                  icon: 'assets/icons/calendar_check_filled.svg',
                  title: '민원 관리',
                  onTap: () {
                    // Navigate to complaint management
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
                    // Navigate to notice registration
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
            SvgPicture.asset(
              icon,
              width: 24,
              height: 24,
              colorFilter: const ColorFilter.mode(
                Color(0xFF006FFF),
                BlendMode.srcIn,
              ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      color: Colors.white,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () {
                // Navigate to attendance list
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
          const SizedBox(height: 16),
        ],
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

                        print('📱 AdminDashboard Drawer - currentUser: ${currentUser?.toJson()}');
                        print('📱 AdminDashboard Drawer - phoneNumber: ${currentUser?.phoneNumber}');

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUser?.name ?? '관리자명',
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
                  title: '입주민 관리',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to resident management
                  },
                ),
                _buildMenuItem(
                  title: '민원 관리',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Navigate to complaint management
                  },
                ),
                _buildMenuItem(
                  title: '담당자 관리',
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/admin/staff-management');
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

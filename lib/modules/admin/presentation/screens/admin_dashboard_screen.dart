import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              // Navigation Bar
              _buildNavigationBar(context),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with background image
                      _buildHeader(),

                      // Separator
                      _buildSeparator(),

                      // Account issuance button
                      _buildAccountIssuanceButton(context),

                      // Menu grid
                      _buildMenuGrid(context),

                      // Bottom spacing for fixed button
                      const SizedBox(height: 140),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Fixed bottom button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildFixedBottomButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationBar(BuildContext context) {
    return Container(
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
          // Notification bell
          Positioned(
            right: 52,
            top: 12,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 24,
                  color: Color(0xFF464A4D),
                ),
                // Badge
                Positioned(
                  top: -4,
                  right: -4,
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
                          height: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Menu icon
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(
                Icons.menu,
                size: 24,
                color: Color(0xFF464A4D),
              ),
              onPressed: () {
                // Menu action
              },
            ),
          ),
        ],
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
          Positioned(
            left: 28,
            top: 309,
            child: Container(
              width: 109,
              height: 40,
              color: Colors.white.withOpacity(0.2),
              // Add your logo widget here
            ),
          ),

          // Building name text
          const Positioned(
            left: 16,
            top: 323,
            child: Text(
              '건물명',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 36,
                height: 1.25,
                color: Color(0xFF17191A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeparator() {
    return Container(
      height: 8,
      color: const Color(0xFFF2F8FC),
      child: Stack(
        children: [
          Positioned(
            left: 16,
            top: 4,
            right: 16,
            child: Container(
              height: 1,
              color: const Color(0xFFBBC5CC).withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 76, 16, 0),
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
                    // Navigate to staff management
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
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
          onPressed: () {
            // Navigate to account issuance
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
}

import 'package:flutter/material.dart';

/// 모든 페이지에서 사용하는 공통 상단 네비게이션바
///
/// 높이: 48px (고정)
/// - 알림 아이콘 (배지 포함)
/// - 메뉴 아이콘
class CommonNavigationBar extends StatelessWidget {
  final int notificationCount;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onMenuTap;
  final bool showNotification;

  const CommonNavigationBar({
    super.key,
    this.notificationCount = 0,
    this.onNotificationTap,
    this.onMenuTap,
    this.showNotification = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EEF2), width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),

          if (showNotification) ...[
            _buildNotificationIcon(),
            const SizedBox(width: 20),
          ],

          // Menu icon
          IconButton(
            icon: const Icon(Icons.menu, size: 24, color: Color(0xFF464A4D)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onMenuTap,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return IconButton(
      tooltip: '알림',
      onPressed: onNotificationTap,
      icon: Badge(
        label: Text(notificationCount > 99 ? '99+' : '$notificationCount'),
        isLabelVisible: notificationCount > 0,
        backgroundColor: const Color(0xFF006FFF),
        textColor: Colors.white,
        child: const Icon(
          Icons.notifications_outlined,
          size: 24,
          color: Color(0xFF464A4D),
        ),
      ),
    );
  }
}

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
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EEF2),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Spacer(),

          // Notification bell with badge
          // _buildNotificationIcon(),

          // const SizedBox(width: 20),

          // Menu icon
          IconButton(
            icon: const Icon(
              Icons.menu,
              size: 24,
              color: Color(0xFF464A4D),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: onMenuTap,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationIcon() {
    return InkWell(
      onTap: onNotificationTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(
              Icons.notifications_outlined,
              size: 24,
              color: Color(0xFF464A4D),
            ),

            // Badge - only show if count > 0
            if (notificationCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  decoration: const BoxDecoration(
                    color: Color(0xFF006FFF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      notificationCount > 99 ? '99+' : '$notificationCount',
                      style: const TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                        color: Colors.white,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

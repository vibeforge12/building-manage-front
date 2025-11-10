import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 공통 앱바 위젯
/// 모든 화면에서 일관된 앱바 스타일을 제공합니다.
/// 하단에 #E8EEF2 색상의 구분선이 자동으로 추가됩니다.
PreferredSizeWidget commonAppBar(
  String title, {
  bool showBackButton = true,
  bool showMenuButton = false,
  VoidCallback? onMenuPressed,
  List<Widget>? actions,
}) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: showBackButton
        ? Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/');
                }
              },
            ),
          )
        : null,
    automaticallyImplyLeading: showBackButton,
    title: Text(
      title,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        height: 1.5,
        color: Color(0xFF464A4D),
      ),
    ),
    centerTitle: true,
    actions: [
      if (showMenuButton && onMenuPressed != null)
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.black),
          onPressed: onMenuPressed,
        ),
      if (actions != null) ...actions,
    ],
    bottom: const PreferredSize(
      preferredSize: Size.fromHeight(1),
      child: Divider(
        height: 1,
        thickness: 1,
        color: Color(0xFFE8EEF2),
      ),
    ),
  );
}

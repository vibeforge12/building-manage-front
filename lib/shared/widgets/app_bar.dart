import 'package:flutter/material.dart';

PreferredSizeWidget commonAppBar(String title, {List<Widget>? actions}) {
  return AppBar(
    title: Text(title, style: TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 16,
        color: Color(0xFF464A4D),
      ),
    ),
    centerTitle: true,
    elevation: 0,
    backgroundColor: Colors.white,
    actions: actions,
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(
        color: const Color(0xFFE0E0E0),
        height: 1,
      ),
    ),
  );
}

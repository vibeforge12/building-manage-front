import 'package:flutter/material.dart';

/// 공고·민원 화면에서 사용하는 글꼴, 구분선, 하단 버튼 규격.
class LifeServiceStyle extends StatelessWidget {
  const LifeServiceStyle({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );
    return Theme(
      data: base.copyWith(
        textTheme: base.textTheme.apply(
          fontFamily: 'Pretendard',
          bodyColor: const Color(0xFF17191A),
          displayColor: const Color(0xFF17191A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
          toolbarHeight: 48,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontFamily: 'Pretendard',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF464A4D),
          ),
          shape: Border(bottom: BorderSide(color: Color(0xFFE8EEF2))),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF006FFF),
            disabledBackgroundColor: const Color(0xFFE8EEF2),
            minimumSize: const Size.fromHeight(56),
            shape: shape,
            textStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF006FFF),
            minimumSize: const Size.fromHeight(56),
            shape: shape,
            side: const BorderSide(color: Color(0xFFE8EEF2)),
            textStyle: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          hintStyle: TextStyle(
            color: Color(0xFFA4ADB2),
            fontFamily: 'Pretendard',
          ),
          filled: true,
          fillColor: Color(0xFFF2F8FC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE8EEF2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            borderSide: BorderSide(color: Color(0xFFE8EEF2)),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
      child: child,
    );
  }
}

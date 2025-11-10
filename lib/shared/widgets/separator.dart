import 'package:flutter/material.dart';

/// 섹션 구분선 위젯
/// Figma 디자인 시스템의 Separator 컴포넌트
class SeparatorWidget extends StatelessWidget {
  final double height;
  final Color backgroundColor;
  final Color? dividerColor;
  final bool showDivider;

  const SeparatorWidget({
    super.key,
    this.height = 8,
    this.backgroundColor = const Color(0xFFF2F8FC),
    this.dividerColor,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: backgroundColor,
      child: showDivider
          ? Stack(
              children: [
                Positioned(
                  left: 16,
                  top: height / 2 - 0.5,
                  right: 16,
                  child: Container(
                    height: 1,
                  ),
                ),
              ],
            )
          : null,
    );
  }
}

import 'package:flutter/material.dart';

Future<bool?> showCustomConfirmationDialog({
  required BuildContext context,
  String? title,
  required Widget content,            // 본문 위젯(없으면 SizedBox.shrink())
  String confirmText = '확인',
  String cancelText = '취소',
  bool isDestructive = false,         // 텍스트 색만 빨강 계열로
  bool barrierDismissible = true,
  bool confirmOnLeft = true,          // ← 이미지처럼 "확인(예)"을 왼쪽에 둘지
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => _CustomConfirmationDialog(
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      isDestructive: isDestructive,
      confirmOnLeft: confirmOnLeft,
    ),
  );
}

class _CustomConfirmationDialog extends StatelessWidget {
  final String? title;
  final Widget content;
  final String confirmText;
  final String cancelText;
  final bool isDestructive;
  final bool confirmOnLeft;

  const _CustomConfirmationDialog({
    super.key,
    this.title,
    required this.content,
    required this.confirmText,
    required this.cancelText,
    required this.isDestructive,
    required this.confirmOnLeft,
  });

  static const _primaryBlue = Color(0xFF006FFF);
  static const _lightBlueBg = Color(0xFFEFF6FF);
  static const _divider = Color(0xFFE8EEF2);

  @override
  Widget build(BuildContext context) {
    // 버튼 공통 스타일
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));

    final confirmBtn = FilledButton(
      onPressed: () => Navigator.of(context).pop(true),
      style: FilledButton.styleFrom(
        backgroundColor: _lightBlueBg,     // 옅은 파랑 배경
        foregroundColor: _primaryBlue,     // 파랑 텍스트
        minimumSize: const Size.fromHeight(64),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
      ),
      child: Text(
        confirmText,
        style: TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: isDestructive ? Colors.red : _primaryBlue,
        ),
      ),
    );

    final cancelBtn = FilledButton(
      onPressed: () => Navigator.of(context).pop(false),
      style: FilledButton.styleFrom(
        backgroundColor: _primaryBlue,     // 진한 파랑 배경
        foregroundColor: Colors.white,     // 흰 텍스트
        minimumSize: const Size.fromHeight(64),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        elevation: 0,
      ),
      child: Text(
        cancelText,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 17,
          color: Colors.white,
        ),
      ),
    );

    // 버튼 배치: confirmOnLeft 이면 [확인, 취소], 아니면 [취소, 확인]
    final buttons = confirmOnLeft
        ? <Widget>[Expanded(child: confirmBtn), const SizedBox(width: 16), Expanded(child: cancelBtn)]
        : <Widget>[Expanded(child: cancelBtn), const SizedBox(width: 16), Expanded(child: confirmBtn)];

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null && title!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17191A),
                    height: 1.4,
                  ),
                ),
              ),
            // 본문(있으면)
            if (!(content is SizedBox && (content as SizedBox).height == 0))
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: DefaultTextStyle(
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: Color(0xFF17191A),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  child: content,
                ),
              ),
            const SizedBox(height: 24),
            Row(children: buttons),
          ],
        ),
      ),
    );
  }
}

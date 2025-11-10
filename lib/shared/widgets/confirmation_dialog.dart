import 'package:flutter/material.dart';

/// 재사용 가능한 확인 다이얼로그
///
/// 일관된 스타일의 확인 다이얼로그를 제공합니다.
class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String confirmText;
  final String cancelText;
  final Color? confirmColor;
  final VoidCallback? onConfirm;

  const ConfirmationDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmText = '예',
    this.cancelText = '아니오',
    this.confirmColor,
    this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF17191A),
        ),
      ),
      content: content != null
          ? Text(
              content!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.red,
              ),
            )
          : null,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            cancelText,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF757B80),
            ),
          ),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, true);
            onConfirm?.call();
          },
          style: FilledButton.styleFrom(
            backgroundColor: confirmColor ?? const Color(0xFF006FFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 다이얼로그 표시 헬퍼 메서드
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? content,
    String confirmText = '예',
    String cancelText = '아니오',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => ConfirmationDialog(
        title: title,
        content: content,
        confirmText: confirmText,
        cancelText: cancelText,
        confirmColor: confirmColor,
      ),
    );
    return result ?? false;
  }
}

/// 정보 알림 다이얼로그 (확인 버튼만)
class InfoDialog extends StatelessWidget {
  final String title;
  final String? content;
  final String confirmText;

  const InfoDialog({
    super.key,
    required this.title,
    this.content,
    this.confirmText = '확인',
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Pretendard',
          fontWeight: FontWeight.w700,
          fontSize: 18,
          color: Color(0xFF17191A),
        ),
      ),
      content: content != null
          ? Text(
              content!,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 14,
                color: Colors.red,
              ),
            )
          : null,
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF006FFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text(
            confirmText,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// 다이얼로그 표시 헬퍼 메서드
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? content,
    String confirmText = '확인',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => InfoDialog(
        title: title,
        content: content,
        confirmText: confirmText,
      ),
    );
  }
}

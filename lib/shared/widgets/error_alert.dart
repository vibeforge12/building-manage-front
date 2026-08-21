import 'package:flutter/material.dart';
import 'package:building_manage_front/core/utils/error_message.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

/// 앱 표준 "실패 안내" 다이얼로그(확인 버튼 1개).
///
/// 실패를 조용히 삼키지 않도록, 예외를 잡은 자리에서 이 함수를 호출한다.
/// [message]를 주면 그대로 쓰고, 없으면 [error]에서 문구를 추출한다.
Future<void> showErrorAlert(
  BuildContext context, {
  required String title,
  Object? error,
  String? message,
  String? fallback,
}) {
  final text = message ??
      (fallback == null
          ? userMessageOf(error)
          : userMessageOf(error, fallback: fallback));

  return showCustomConfirmationDialog(
    context: context,
    title: title,
    content: Text(text),
    confirmText: '확인',
    cancelText: '', // 빈 문자열로 취소 버튼 숨김
    barrierDismissible: false,
  );
}

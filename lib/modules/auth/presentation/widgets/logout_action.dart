import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_alert.dart';
import '../providers/auth_state_provider.dart';

Future<bool> logoutWithFeedback(BuildContext context, WidgetRef ref) async {
  try {
    await ref.read(authStateProvider.notifier).logout();
    return true;
  } catch (error) {
    if (!context.mounted) return false;
    await showErrorAlert(
      context,
      title: '로그아웃 실패',
      error: error,
      fallback: '알림 등록을 해제하지 못했습니다. 연결을 확인하고 다시 시도해 주세요.',
    );
    return false;
  }
}

import 'package:flutter/material.dart';

/// 이미 올린 공고문의 알림 발송 여부. 읽기 상태에서만 나온다.
///
/// 목록에 두지 않고 상세에만 두는 이유: 목록에서 필요한 것은
/// "무엇이 언제까지 걸려 있는가" 이고, 알림을 보냈는지는 한 건을
/// 들여다볼 때 확인하는 값이다.
///
/// 등록 시점에만 정해지고 나중에 바꿀 수 없으므로 읽기 전용으로 보여준다
/// (수정으로는 알림을 다시 보낼 수 없다 — 그래서 수정 화면에 체크박스가 없다).
class BulletinPushStatus extends StatelessWidget {
  const BulletinPushStatus({super.key, required this.sent});

  final bool sent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8FC),
        border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            sent
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            size: 20,
            color: sent ? const Color(0xFF006FFF) : const Color(0xFF757B80),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              sent ? '입주민에게 알림을 보냈습니다' : '알림을 보내지 않았습니다',
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: sent
                    ? const Color(0xFF17191A)
                    : const Color(0xFF757B80),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

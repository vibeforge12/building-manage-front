import 'package:flutter/material.dart';

/// 등록 시 입주민에게 푸시를 보낼지 고르는 체크박스.
///
/// 기본이 꺼짐인 이유를 등록자에게 함께 보여준다. 이유를 모르면 매번 켜게 되고,
/// 그러면 입주민이 앱 알림 자체를 꺼버려 정작 급한 공지가 닿지 않는다.
class BulletinPushCheckbox extends StatelessWidget {
  const BulletinPushCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    // 박스 전체가 하나의 버튼이다. 체크박스만 누를 수 있게 두면 옆의 설명 글을 눌러도
    // 아무 일이 없어, 체크박스 자체를 정확히 겨눠야 한다.
    // 위의 건물·게시기간 박스도 박스 전체를 누르므로 조작 방식이 같아진다.
    //
    // 체크박스는 자기 탭을 스스로 처리하므로(부모로 전달되지 않는다) 두 번 토글되지 않는다.
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FC),
          border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Checkbox(
              value: value,
              activeColor: const Color(0xFF006FFF),
              onChanged: (next) => onChanged(next ?? false),
            ),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '입주민에게 알림 보내기',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF17191A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    '공고문마다 알림을 보내면 입주민이 알림을 꺼버립니다. 긴급할 때만 사용해주세요.',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFF757B80),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

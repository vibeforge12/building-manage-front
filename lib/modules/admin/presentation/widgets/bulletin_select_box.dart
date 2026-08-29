import 'package:flutter/material.dart';

/// 공고문 등록 화면 상단의 선택 컨트롤 한 칸.
///
/// 공지 등록의 드롭다운과 같은 생김새로 맞춘다. 건물 선택과 게시 기간이 이것을 함께 쓰므로
/// 한쪽만 모양이 바뀌는 일이 없도록 여기 한 곳에 둔다.
class BulletinSelectBox extends StatelessWidget {
  const BulletinSelectBox({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  /// 값이 선택된 상태의 글자.
  static const textStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: Color(0xFF17191A),
  );

  /// 아직 고르지 않은 상태의 글자.
  static const hintStyle = TextStyle(
    fontFamily: 'Pretendard',
    fontWeight: FontWeight.w400,
    fontSize: 16,
    color: Color(0xFF757B80),
  );

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F8FC),
        border: Border.all(color: const Color(0xFFE8EEF2), width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
    return onTap == null ? box : GestureDetector(onTap: onTap, child: box);
  }
}

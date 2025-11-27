import 'package:flutter/material.dart';

/// 약관 동의 체크박스 아이템 위젯
class ConsentCheckboxItem extends StatelessWidget {
  /// 약관 제목
  final String title;

  /// 체크 여부
  final bool isChecked;

  /// 필수 여부
  final bool isRequired;

  /// 전체 동의 항목인지 여부
  final bool isAllAgree;

  /// 체크 상태 변경 콜백
  final ValueChanged<bool> onChanged;

  /// 상세 보기 탭 콜백 (null이면 화살표 미표시)
  final VoidCallback? onDetailTap;

  const ConsentCheckboxItem({
    super.key,
    required this.title,
    required this.isChecked,
    required this.isRequired,
    this.isAllAgree = false,
    required this.onChanged,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: isAllAgree ? 16 : 12,
          horizontal: 4,
        ),
        child: Row(
          children: [
            // V 체크 아이콘
            Icon(
              Icons.check,
              color: isChecked
                  ? const Color(0xFF006FFF)
                  : const Color(0xFFD1D5DB),
              size: isAllAgree ? 24 : 22,
            ),
            const SizedBox(width: 12),

            // 제목 텍스트
            Expanded(
              child: Text(
                _buildTitle(),
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontSize: isAllAgree ? 16 : 14,
                  fontWeight: isAllAgree ? FontWeight.w700 : FontWeight.w400,
                  color: const Color(0xFF17191A),
                ),
              ),
            ),

            // 상세 보기 화살표 (onDetailTap이 있을 때만)
            if (onDetailTap != null)
              GestureDetector(
                onTap: onDetailTap,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.chevron_right,
                    color: Color(0xFFBDC5CB),
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _buildTitle() {
    if (isAllAgree) {
      return title;
    }
    final prefix = isRequired ? '[필수]' : '[선택]';
    return '$prefix $title';
  }
}

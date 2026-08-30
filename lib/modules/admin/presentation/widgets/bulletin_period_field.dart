import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'bulletin_select_box.dart';

/// 게시 기간을 고르는 칸.
///
/// 건물 선택과 같은 박스 하나로 두고, 실제 선택은 시트에서 한다.
/// 칩과 날짜 입력줄을 폼에 그대로 펼치면 상단 선택 영역에서 이것만 모양이 달라진다.
/// 이 저장소의 상단 선택 컨트롤은 전부 "채운 박스를 눌러 고르는" 형태다.
///
/// 시작·종료가 둘 다 비면 무기한 게시다(기본값).
class BulletinPeriodField extends StatelessWidget {
  const BulletinPeriodField({
    super.key,
    required this.postedFrom,
    required this.postedUntil,
    required this.onChanged,
    this.readOnly = false,
  });

  final DateTime? postedFrom;
  final DateTime? postedUntil;

  /// 고른 기간을 부모에게 돌려준다. 둘 다 `null` 이면 무기한.
  final void Function(DateTime? from, DateTime? until) onChanged;

  /// 읽기 모드에서는 기간을 보여 주기만 하고 달력을 열지 않는다.
  final bool readOnly;

  static String formatDate(DateTime date) =>
      DateFormat('yyyy.MM.dd').format(date);

  @override
  Widget build(BuildContext context) {
    final summary = switch ((postedFrom, postedUntil)) {
      (null, null) => '무기한 게시',
      (final from?, null) => '${formatDate(from)}부터 무기한',
      (null, final until?) => '${formatDate(until)}까지 게시',
      (final from?, final until?) =>
        '${formatDate(from)} ~ ${formatDate(until)}',
    };
    final isDefault = postedFrom == null && postedUntil == null;

    return BulletinSelectBox(
      onTap: readOnly ? null : () => _openPicker(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
              style: isDefault
                  ? BulletinSelectBox.hintStyle
                  : BulletinSelectBox.textStyle,
            ),
          ),
          const Icon(Icons.keyboard_arrow_down,
              size: 24, color: Color(0xFF757B80)),
        ],
      ),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    // 시트 안에서 고른 값을 지역 변수에 담아 두고, 바뀔 때마다 부모에게 올린다.
    // 부모 상태를 바로 고치지 않으면 시트를 닫기 전까지 요약 줄이 옛 값을 보인다.
    DateTime? from = postedFrom;
    DateTime? until = postedUntil;

    Future<DateTime?> pickDate(BuildContext ctx, DateTime? current) {
      final now = DateTime.now();
      return showDatePicker(
        context: ctx,
        initialDate: current ?? now,
        firstDate: DateTime(now.year - 1),
        lastDate: DateTime(now.year + 5),
        locale: const Locale('ko', 'KR'),
      );
    }

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '게시 기간',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Color(0xFF17191A),
                    ),
                  ),
                ),
              ),
              const Divider(height: 1, color: Color(0xFFE8EEF2)),
              _option(
                label: '무기한 게시',
                description: '직접 내릴 때까지 계속 보입니다.',
                selected: from == null && until == null,
                onTap: () {
                  setSheetState(() {
                    from = null;
                    until = null;
                    onChanged(null, null);
                  });
                },
              ),
              _option(
                label: until == null ? '종료일 지정' : '${formatDate(until!)}까지',
                description: '기간이 지나면 입주민 화면에서 자동으로 사라집니다.',
                selected: until != null,
                onTap: () async {
                  final picked = await pickDate(context, until);
                  if (picked == null) return;
                  setSheetState(() {
                    // 종료일은 그날 끝까지 게시되어야 한다.
                    // 자정으로 두면 그날 하루가 통째로 빠진다.
                    until = DateTime(
                        picked.year, picked.month, picked.day, 23, 59, 59);
                    onChanged(from, until);
                  });
                },
              ),
              _option(
                label:
                    from == null ? '시작일 지정 (예약 게시)' : '${formatDate(from!)}부터',
                description: '지정한 날짜가 되어야 입주민에게 보입니다.',
                selected: from != null,
                onTap: () async {
                  final picked = await pickDate(context, from);
                  if (picked == null) return;
                  setSheetState(() {
                    from = DateTime(picked.year, picked.month, picked.day);
                    onChanged(from, until);
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006FFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      '확인',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option({
    required String label,
    required String description,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: selected
                          ? const Color(0xFF006FFF)
                          : const Color(0xFF17191A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFF757B80),
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: Color(0xFF006FFF)),
          ],
        ),
      ),
    );
  }
}

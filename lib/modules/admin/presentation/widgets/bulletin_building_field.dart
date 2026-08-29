import 'package:flutter/material.dart';

import 'bulletin_select_box.dart';

/// 본사가 게시할 건물을 고르는 칸.
///
/// 폼 안에 체크박스를 늘어놓지 않고 요약 한 줄 + 바텀시트로 둔다.
/// 본사가 건물을 수십 개 가질 수 있어, 체크박스를 깔면 아래 입력란이 화면 밖으로 밀린다.
///
/// [selectedIds] 를 **직접 고쳐서** 부모 상태를 바꾸고 [onChanged] 로 다시 그리게 한다.
/// 시트가 열린 뒤에도 뒤쪽 요약 줄이 함께 갱신되어야 하기 때문이다.
class BulletinBuildingField extends StatelessWidget {
  const BulletinBuildingField({
    super.key,
    required this.buildings,
    required this.selectedIds,
    required this.onChanged,
  });

  /// `{'id': ..., 'name': ...}` 목록. 서버가 내려준 순서를 그대로 쓴다.
  final List<Map<String, dynamic>> buildings;
  final Set<String> selectedIds;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selectedNames = buildings
        .where((b) => selectedIds.contains(b['id']))
        .map((b) => b['name']?.toString() ?? '')
        .toList();

    final summary = switch (selectedNames.length) {
      0 => '게시할 건물 선택',
      1 => selectedNames.first,
      _ => '${selectedNames.first} 외 ${selectedNames.length - 1}곳',
    };

    return BulletinSelectBox(
      onTap: () => _openPicker(context),
      child: Row(
        children: [
          Expanded(
            child: Text(
              summary,
              style: selectedNames.isEmpty
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
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final allSelected =
              buildings.isNotEmpty && selectedIds.length == buildings.length;

          return SafeArea(
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            '게시 건물 선택',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                              color: Color(0xFF17191A),
                            ),
                          ),
                        ),
                        // 본사의 실제 용도가 "전 건물 안내" 라 전체 선택이 사실상 필수다.
                        TextButton(
                          onPressed: () {
                            setSheetState(() {
                              if (allSelected) {
                                selectedIds.clear();
                              } else {
                                selectedIds
                                  ..clear()
                                  ..addAll(
                                      buildings.map((b) => b['id'].toString()));
                              }
                              onChanged();
                            });
                          },
                          child: Text(
                            allSelected ? '전체 해제' : '전체 선택',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Color(0xFF006FFF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFE8EEF2)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: buildings.length,
                      itemBuilder: (context, index) {
                        final building = buildings[index];
                        final id = building['id'].toString();
                        return CheckboxListTile(
                          value: selectedIds.contains(id),
                          activeColor: const Color(0xFF006FFF),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: Text(
                            building['name']?.toString() ?? '',
                            style: const TextStyle(
                              fontFamily: 'Pretendard',
                              fontSize: 15,
                              color: Color(0xFF17191A),
                            ),
                          ),
                          onChanged: (value) {
                            setSheetState(() {
                              if (value == true) {
                                selectedIds.add(id);
                              } else {
                                selectedIds.remove(id);
                              }
                              onChanged();
                            });
                          },
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006FFF),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          '${selectedIds.length}곳 선택 완료',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

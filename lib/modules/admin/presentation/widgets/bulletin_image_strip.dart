import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// 붙인 사진 미리보기 줄.
///
/// 첨부 버튼은 제목 오른쪽에 따로 있으므로 여기엔 라벨을 두지 않는다.
/// (민원 등록도 같은 구조다 — 아이콘으로 붙이고, 미리보기는 본문 위에 나온다)
///
/// 서버에 이미 있는 사진([existingUrls], 서명 URL)과 기기에서 방금 고른 사진([pickedImages])을
/// 이 순서로 이어 붙인다. 저장할 때도 같은 순서가 표시 순서가 된다.
class BulletinImageStrip extends StatelessWidget {
  const BulletinImageStrip({
    super.key,
    required this.existingUrls,
    required this.pickedImages,
    required this.maxImages,
    required this.onRemoveExisting,
    required this.onRemovePicked,
  });

  final List<String> existingUrls;
  final List<XFile> pickedImages;
  final int maxImages;
  final ValueChanged<int> onRemoveExisting;
  final ValueChanged<int> onRemovePicked;

  int get _total => existingUrls.length + pickedImages.length;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              '사진 $_total / $maxImages',
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 13,
                color: Color(0xFF757B80),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (int i = 0; i < existingUrls.length; i++)
                _Thumb(
                  onRemove: () => onRemoveExisting(i),
                  child: CachedNetworkImage(
                    imageUrl: existingUrls[i],
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Color(0xFF757B80)),
                  ),
                ),
              for (int i = 0; i < pickedImages.length; i++)
                _Thumb(
                  onRemove: () => onRemovePicked(i),
                  // 방금 고른 사진은 아직 서버에 없다. XFile.path 는 기기 안의 파일 경로라
                  // 네트워크 이미지로 그리면 반드시 실패한다. 등록 화면에서만 안 보이고
                  // 올린 뒤 상세에서는 보였던 이유가 이것이다(상세는 서명 URL 을 받는다).
                  child: Image.file(
                    File(pickedImages[i].path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFF2F8FC),
                      child: const Icon(Icons.image_outlined,
                          color: Color(0xFF757B80)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.child, required this.onRemove});

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: child),
          Positioned(
            top: 2,
            right: 2,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

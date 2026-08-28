import 'package:equatable/equatable.dart';

/// 공고문 노출 상태.
enum BulletinStatus {
  visible,
  hidden,
}

/// 공고문.
///
/// 엘리베이터 게시판의 종이 공고문을 옮긴 것이다. 공지사항(Notice)과 별도 엔티티인 이유는
/// 서버에서도 별도 테이블(bulletins)이기 때문이다 — 작성자가 본사·관리자·담당자 셋이고
/// 게시 기간이 있어 공지와 필드가 다르다.
class Bulletin extends Equatable {
  final String id;
  final String title;

  /// 본문. 이미지만 있는 공고문이 허용되므로 비어 있을 수 있다.
  final String? content;

  /// 이미지 URL 목록(서버가 서명한 URL). 순서가 곧 표시 순서이며 최대 5장이다.
  final List<String> imageUrls;

  final String buildingId;
  final String? buildingName;

  /// 같은 등록으로 생긴 공고문을 묶는 값. 본사가 여러 건물에 한 번에 올린 건을 함께 다룰 때 쓴다.
  final String batchId;

  final BulletinStatus status;

  /// 게시 시작. null 이면 등록 즉시 게시된 것이다.
  final DateTime? postedFrom;

  /// 게시 종료. null 이면 무기한 게시다.
  final DateTime? postedUntil;

  /// 등록 시 입주민 푸시가 실제로 발송됐는지.
  final bool pushSent;

  /// 이 공고문을 보고 있는 사용자가 수정·삭제할 수 있는지. 서버가 판단해 내려준다.
  ///
  /// 작성자 정보를 받아 앱이 직접 판단하지 않는 이유는, 그렇게 하면 권한 규칙이 서버와 앱
  /// 두 곳에 생기고 구버전 앱이 낡은 규칙을 계속 쓰게 되기 때문이다.
  final bool canManage;

  final DateTime createdAt;
  final DateTime updatedAt;

  const Bulletin({
    required this.id,
    required this.title,
    this.content,
    required this.imageUrls,
    required this.buildingId,
    this.buildingName,
    required this.batchId,
    required this.status,
    this.postedFrom,
    this.postedUntil,
    required this.pushSent,
    required this.canManage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 이미지가 하나라도 있는지.
  bool get hasImages => imageUrls.isNotEmpty;

  /// 기간 제한 없이 계속 게시되는 공고문인지.
  bool get isIndefinite => postedFrom == null && postedUntil == null;

  /// 게시 기간이 지났는지. 관리 화면에서 지난 공고문을 구분해 보여줄 때 쓴다.
  bool get isExpired =>
      postedUntil != null && DateTime.now().isAfter(postedUntil!);

  /// 아직 게시 시작 전인지(예약).
  bool get isScheduled =>
      postedFrom != null && DateTime.now().isBefore(postedFrom!);

  factory Bulletin.fromJson(Map<String, dynamic> json) {
    final building = json['building'] as Map<String, dynamic>?;

    return Bulletin(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String?,
      imageUrls: (json['imageUrls'] as List<dynamic>? ?? const [])
          .map((url) => url.toString())
          .toList(),
      buildingId: json['buildingId'] as String? ?? '',
      buildingName: building?['name'] as String?,
      batchId: json['batchId'] as String? ?? '',
      status: _parseStatus(json['status'] as String?),
      postedFrom: _parseDate(json['postedFrom']),
      postedUntil: _parseDate(json['postedUntil']),
      pushSent: json['pushSent'] as bool? ?? false,
      canManage: json['canManage'] as bool? ?? false,
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString())?.toLocal();
  }

  static BulletinStatus _parseStatus(String? value) {
    return value?.toUpperCase() == 'HIDDEN'
        ? BulletinStatus.hidden
        : BulletinStatus.visible;
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        imageUrls,
        buildingId,
        buildingName,
        batchId,
        status,
        postedFrom,
        postedUntil,
        pushSent,
        canManage,
        createdAt,
        updatedAt,
      ];
}

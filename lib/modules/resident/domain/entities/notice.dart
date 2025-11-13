import 'package:equatable/equatable.dart';

/// 공지사항 타입
enum NoticeType {
  notice, // 일반 공지
  event,  // 이벤트
}

/// 공지사항 엔티티
class Notice extends Equatable {
  final String id;
  final String title;
  final String content;
  final NoticeType type;
  final String? imageUrl;
  final String buildingId;
  final DateTime createdAt;
  final DateTime? eventStartDate;
  final DateTime? eventEndDate;

  const Notice({
    required this.id,
    required this.title,
    required this.content,
    required this.type,
    this.imageUrl,
    required this.buildingId,
    required this.createdAt,
    this.eventStartDate,
    this.eventEndDate,
  });

  /// 이벤트 여부
  bool get isEvent => type == NoticeType.event;

  /// 이벤트 진행 중 여부
  bool get isEventActive {
    if (!isEvent) return false;
    if (eventStartDate == null || eventEndDate == null) return false;

    final now = DateTime.now();
    return now.isAfter(eventStartDate!) && now.isBefore(eventEndDate!);
  }

  /// JSON에서 엔티티 생성
  factory Notice.fromJson(Map<String, dynamic> json) {
    return Notice(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      type: _parseType(json['type'] as String? ?? json['isEvent'] as String?),
      imageUrl: json['imageUrl'] as String?,
      buildingId: json['buildingId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      eventStartDate: json['eventStartDate'] != null
          ? DateTime.parse(json['eventStartDate'] as String)
          : null,
      eventEndDate: json['eventEndDate'] != null
          ? DateTime.parse(json['eventEndDate'] as String)
          : null,
    );
  }

  /// 타입 문자열을 enum으로 변환
  static NoticeType _parseType(String? type) {
    if (type == null) return NoticeType.notice;

    switch (type.toUpperCase()) {
      case 'EVENT':
      case 'TRUE':
        return NoticeType.event;
      case 'NOTICE':
      case 'FALSE':
      default:
        return NoticeType.notice;
    }
  }

  /// enum을 문자열로 변환
  String _typeToString() {
    return type == NoticeType.event ? 'EVENT' : 'NOTICE';
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': _typeToString(),
      'imageUrl': imageUrl,
      'buildingId': buildingId,
      'createdAt': createdAt.toIso8601String(),
      'eventStartDate': eventStartDate?.toIso8601String(),
      'eventEndDate': eventEndDate?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        type,
        imageUrl,
        buildingId,
        createdAt,
        eventStartDate,
        eventEndDate,
      ];
}

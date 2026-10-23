import 'package:equatable/equatable.dart';

enum LifeServiceDisplayStatus { recruiting, closed, completed }

enum LifeServiceApplicationStatus { applied, canceled }

class LifeService extends Equatable {
  const LifeService({
    required this.id,
    required this.title,
    required this.description,
    required this.applicationStartAt,
    required this.applicationEndAt,
    required this.serviceStartAt,
    required this.serviceEndAt,
    this.location,
    this.capacity,
    required this.applicantCount,
    required this.status,
    this.applicationStatus,
    required this.canApply,
    required this.canCancel,
    required this.canManage,
    this.canClose = false,
    this.imageKeys = const [],
    this.imageUrls = const [],
  });

  final String id;
  final String title;
  final String description;
  final DateTime applicationStartAt;
  final DateTime applicationEndAt;
  final DateTime serviceStartAt;
  final DateTime serviceEndAt;
  final String? location;
  final int? capacity;
  final int applicantCount;
  final LifeServiceDisplayStatus status;
  final LifeServiceApplicationStatus? applicationStatus;
  final bool canApply;
  final bool canCancel;
  final bool canManage;
  final bool canClose;
  final List<String> imageKeys;
  final List<String> imageUrls;

  factory LifeService.fromJson(Map<String, dynamic> json) => LifeService(
    id: json['id'] as String? ?? '',
    title: json['title'] as String? ?? '',
    description: json['description'] as String? ?? '',
    applicationStartAt: _date(json['applicationStartAt']),
    applicationEndAt: _date(json['applicationEndAt']),
    serviceStartAt: _date(json['serviceStartAt']),
    serviceEndAt: _date(json['serviceEndAt']),
    location: json['location'] as String?,
    capacity: json['capacity'] as int?,
    applicantCount: json['applicantCount'] as int? ?? 0,
    status: switch (json['status']) {
      'RECRUITING' => LifeServiceDisplayStatus.recruiting,
      'COMPLETED' => LifeServiceDisplayStatus.completed,
      _ => LifeServiceDisplayStatus.closed,
    },
    applicationStatus: switch (json['applicationStatus']) {
      'APPLIED' => LifeServiceApplicationStatus.applied,
      'CANCELED' => LifeServiceApplicationStatus.canceled,
      _ => null,
    },
    canApply: json['canApply'] as bool? ?? false,
    canCancel: json['canCancel'] as bool? ?? false,
    canManage: json['canManage'] as bool? ?? false,
    // Fail closed against an older server rather than guessing from display
    // status, which conflates capacity reached and explicit manual closure.
    canClose: json['canClose'] as bool? ?? false,
    imageKeys: (json['imageKeys'] as List? ?? const []).cast<String>(),
    imageUrls: (json['imageUrls'] as List? ?? const []).cast<String>(),
  );

  static DateTime _date(dynamic value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  @override
  List<Object?> get props => [
    id,
    title,
    description,
    applicationStartAt,
    applicationEndAt,
    serviceStartAt,
    serviceEndAt,
    location,
    capacity,
    applicantCount,
    status,
    applicationStatus,
    canApply,
    canCancel,
    canManage,
    canClose,
    imageKeys,
    imageUrls,
  ];
}

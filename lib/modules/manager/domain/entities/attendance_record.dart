import 'package:equatable/equatable.dart';

/// 출퇴근 기록 타입
enum AttendanceRecordType {
  checkIn,  // CHECK_IN
  checkOut, // CHECK_OUT
}

/// 출퇴근 기록 엔티티
class AttendanceRecord extends Equatable {
  final String id;
  final AttendanceRecordType type;
  final DateTime createdAt;

  const AttendanceRecord({
    required this.id,
    required this.type,
    required this.createdAt,
  });

  /// JSON에서 엔티티 생성
  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: json['id'] as String,
      type: _parseType(json['type'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// 타입 문자열을 enum으로 변환
  static AttendanceRecordType _parseType(String type) {
    switch (type) {
      case 'CHECK_IN':
        return AttendanceRecordType.checkIn;
      case 'CHECK_OUT':
        return AttendanceRecordType.checkOut;
      default:
        throw ArgumentError('Unknown attendance type: $type');
    }
  }

  /// JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == AttendanceRecordType.checkIn ? 'CHECK_IN' : 'CHECK_OUT',
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, type, createdAt];
}

/// 월별 출퇴근 기록 응답
class MonthlyAttendanceResponse extends Equatable {
  final int year;
  final int month;
  final List<AttendanceRecord> records;

  const MonthlyAttendanceResponse({
    required this.year,
    required this.month,
    required this.records,
  });

  /// JSON에서 엔티티 생성
  factory MonthlyAttendanceResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>;
    final recordsList = data['records'] as List<dynamic>;

    return MonthlyAttendanceResponse(
      year: data['year'] as int,
      month: data['month'] as int,
      records: recordsList
          .map((record) => AttendanceRecord.fromJson(record as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [year, month, records];
}

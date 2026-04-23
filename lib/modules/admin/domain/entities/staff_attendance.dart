import 'package:equatable/equatable.dart';

/// 직원 부서 정보
class StaffDepartment extends Equatable {
  final String id;
  final String name;

  const StaffDepartment({required this.id, required this.name});

  factory StaffDepartment.fromJson(Map<String, dynamic> json) {
    return StaffDepartment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// 일별 출퇴근 기록 (월별 캘린더용)
class StaffDayRecord extends Equatable {
  final String date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  const StaffDayRecord({
    required this.date,
    this.checkIn,
    this.checkOut,
  });

  factory StaffDayRecord.fromJson(Map<String, dynamic> json) {
    return StaffDayRecord(
      date: json['date'] as String? ?? '',
      checkIn: json['checkIn'] != null
          ? DateTime.parse(json['checkIn'] as String).toLocal()
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String).toLocal()
          : null,
    );
  }

  @override
  List<Object?> get props => [date, checkIn, checkOut];
}

/// 직원 월별 출퇴근 데이터
class StaffMonthlyData extends Equatable {
  final String staffId;
  final String name;
  final StaffDepartment? department;
  final List<StaffDayRecord> days;

  const StaffMonthlyData({
    required this.staffId,
    required this.name,
    this.department,
    required this.days,
  });

  factory StaffMonthlyData.fromJson(Map<String, dynamic> json) {
    return StaffMonthlyData(
      staffId: json['staffId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: json['department'] != null
          ? StaffDepartment.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      days: (json['days'] as List<dynamic>?)
          ?.map((d) => StaffDayRecord.fromJson(d as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [staffId, name, department, days];
}

/// 월별 출퇴근 응답
class StaffAttendanceMonthly extends Equatable {
  final int year;
  final int month;
  final List<StaffMonthlyData> staffs;

  const StaffAttendanceMonthly({
    required this.year,
    required this.month,
    required this.staffs,
  });

  factory StaffAttendanceMonthly.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceMonthly(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      staffs: (json['staffs'] as List<dynamic>?)
          ?.map((s) => StaffMonthlyData.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  @override
  List<Object?> get props => [year, month, staffs];
}

/// 직원 일별 출퇴근 현황
class StaffDailyAttendance extends Equatable {
  final String staffId;
  final String name;
  final StaffDepartment? department;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status; // NOT_ARRIVED, WORKING, LEFT

  const StaffDailyAttendance({
    required this.staffId,
    required this.name,
    this.department,
    this.checkIn,
    this.checkOut,
    required this.status,
  });

  factory StaffDailyAttendance.fromJson(Map<String, dynamic> json) {
    return StaffDailyAttendance(
      staffId: json['staffId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      department: json['department'] != null
          ? StaffDepartment.fromJson(json['department'] as Map<String, dynamic>)
          : null,
      checkIn: json['checkIn'] != null
          ? DateTime.parse(json['checkIn'] as String).toLocal()
          : null,
      checkOut: json['checkOut'] != null
          ? DateTime.parse(json['checkOut'] as String).toLocal()
          : null,
      status: json['status'] as String? ?? 'NOT_ARRIVED',
    );
  }

  @override
  List<Object?> get props => [staffId, name, department, checkIn, checkOut, status];
}

/// 출퇴근 요약
class AttendanceSummary extends Equatable {
  final int total;
  final int working;
  final int left;
  final int notArrived;

  const AttendanceSummary({
    required this.total,
    required this.working,
    required this.left,
    required this.notArrived,
  });

  factory AttendanceSummary.fromJson(Map<String, dynamic> json) {
    return AttendanceSummary(
      total: json['total'] as int,
      working: json['working'] as int,
      left: json['left'] as int,
      notArrived: json['notArrived'] as int,
    );
  }

  @override
  List<Object?> get props => [total, working, left, notArrived];
}

/// 일별 출퇴근 현황 응답
class StaffAttendanceDaily extends Equatable {
  final String date;
  final List<StaffDailyAttendance> staffs;
  final AttendanceSummary summary;

  const StaffAttendanceDaily({
    required this.date,
    required this.staffs,
    required this.summary,
  });

  factory StaffAttendanceDaily.fromJson(Map<String, dynamic> json) {
    return StaffAttendanceDaily(
      date: json['date'] as String? ?? '',
      staffs: (json['staffs'] as List<dynamic>?)
          ?.map((s) => StaffDailyAttendance.fromJson(s as Map<String, dynamic>))
          .toList() ?? [],
      summary: json['summary'] != null
          ? AttendanceSummary.fromJson(json['summary'] as Map<String, dynamic>)
          : const AttendanceSummary(total: 0, working: 0, left: 0, notArrived: 0),
    );
  }

  @override
  List<Object?> get props => [date, staffs, summary];
}

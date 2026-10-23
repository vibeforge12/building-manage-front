import 'package:building_manage_front/modules/life_service/domain/entities/life_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LifeService.fromJson', () {
    test('신청 상태와 서버 시간을 앱 도메인 값으로 변환한다', () {
      final service = LifeService.fromJson({
        'id': 'service-1',
        'title': '월간 소독',
        'description': '세대 방문 소독',
        'applicationStartAt': '2026-10-20T09:00:00+09:00',
        'applicationEndAt': '2026-10-22T18:00:00+09:00',
        'serviceStartAt': '2026-10-23T10:00:00+09:00',
        'serviceEndAt': '2026-10-23T12:00:00+09:00',
        'status': 'RECRUITING',
        'applicationStatus': 'APPLIED',
        'applicantCount': 3,
        'capacity': 10,
        'canApply': false,
        'canCancel': true,
        'canManage': false,
      });

      expect(service.status, LifeServiceDisplayStatus.recruiting);
      expect(service.applicationStatus, LifeServiceApplicationStatus.applied);
      expect(service.applicantCount, 3);
      expect(service.capacity, 10);
      expect(service.canCancel, isTrue);
      expect(service.serviceStartAt.isUtc, isFalse);
    });

    test('없는 선택 값은 안전한 기본값을 사용한다', () {
      final service = LifeService.fromJson({
        'id': 'service-2',
        'title': '점검',
        'description': '안내',
        'applicationStartAt': '2026-10-20T00:00:00Z',
        'applicationEndAt': '2026-10-21T00:00:00Z',
        'serviceStartAt': '2026-10-22T00:00:00Z',
        'serviceEndAt': '2026-10-22T01:00:00Z',
        'status': 'CLOSED',
      });

      expect(service.status, LifeServiceDisplayStatus.closed);
      expect(service.applicationStatus, isNull);
      expect(service.capacity, isNull);
      expect(service.canApply, isFalse);
      expect(service.canClose, isFalse);
    });
  });
}

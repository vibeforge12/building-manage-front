import 'package:flutter/material.dart';
import '../../domain/entities/life_service.dart';

/// 신청 가능 항목이 없으면 영역 전체를 숨긴다. 전체 목록은 홈 메뉴에서 연다.
class ResidentLifeServiceSection extends StatelessWidget {
  const ResidentLifeServiceSection({
    super.key,
    required this.services,
    this.isLoading = false,
    this.error,
    required this.onViewAll,
    required this.onOpen,
    required this.onRetry,
  });

  final List<LifeService> services;
  final bool isLoading;
  final String? error;
  final VoidCallback onViewAll;
  final ValueChanged<String> onOpen;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (!isLoading && error == null && services.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '서비스 신청',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    color: Color(0xFF17191A),
                  ),
                ),
              ),
              TextButton(onPressed: onViewAll, child: const Text('전체보기')),
            ],
          ),
          const SizedBox(height: 8),
          if (isLoading && services.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null) ...[
            Text(error!, style: const TextStyle(color: Color(0xFF757B80))),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ] else
            ...services
                .take(2)
                .map(
                  (service) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: const Color(0xFFF7FAFC),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onOpen(service.id),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF3FF),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.volunteer_activism,
                                  color: Color(0xFF006FFF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      service.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      _statusLabel(service),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            service.status ==
                                                LifeServiceDisplayStatus
                                                    .recruiting
                                            ? const Color(0xFF006FFF)
                                            : const Color(0xFF757B80),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Color(0xFF757B80),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  String _statusLabel(LifeService service) {
    if (service.status == LifeServiceDisplayStatus.completed) return '진행 완료';
    final applied =
        service.applicationStatus == LifeServiceApplicationStatus.applied;
    if (service.status == LifeServiceDisplayStatus.closed) {
      return applied ? '신청 완료 · 신청 마감' : '신청 마감';
    }
    return applied ? '신청 완료' : '신청 가능';
  }
}

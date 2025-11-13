import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class ResidentApprovalPendingScreen extends ConsumerWidget {
  const ResidentApprovalPendingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(currentUserProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '회원가입',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF464A4D),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: const Color(0xFFE8EEF2),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 대기 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8FC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.schedule_outlined,
                        size: 40,
                        color: Color(0xFF006FFF),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    Text(
                      '관리자 승인 대기중',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF464A4D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 설명 텍스트
                    Text(
                      '입주하신 ${currentUser?.dong}동 ${currentUser?.ho}호의\n건물 관리자의 승인을 기다리고 있습니다.\n\n승인 시 입주민 서비스를 이용할 수 있습니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF808080),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 정보 카드
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F8FC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE8EEF2),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '제출된 정보',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF464A4D),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow('이름', currentUser?.name ?? '-'),
                          const SizedBox(height: 8),
                          _buildInfoRow('동/호수', '${currentUser?.dong}동 ${currentUser?.ho}호'),
                          const SizedBox(height: 8),
                          _buildInfoRow('전화번호', currentUser?.phoneNumber ?? '-'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: FilledButton(
                onPressed: () async {
                  // 로그아웃
                  await ref.read(authStateProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/');
                  }
                },
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: const Color(0xFF006FFF),
                ),
                child: const Text('로그아웃'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF808080),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF464A4D),
          ),
        ),
      ],
    );
  }
}

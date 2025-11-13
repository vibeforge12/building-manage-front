import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidentApprovalRejectedScreen extends ConsumerWidget {
  final String? reason;

  const ResidentApprovalRejectedScreen({
    super.key,
    this.reason,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    // 거부 아이콘
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_outlined,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    Text(
                      '승인이 보류되었습니다',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF464A4D),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // 설명 텍스트
                    Text(
                      '건물 관리자가 가입을 보류했습니다.\n\n아래 사항을 확인하신 후\n다시 신청해주시기 바랍니다.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF808080),
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // 거부 사유 카드
                    if (reason != null && reason!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFD5D5),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '보류 사유',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              reason!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF464A4D),
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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
                              '확인 사항',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF464A4D),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildCheckItem('동/호수 정보 확인'),
                            const SizedBox(height: 8),
                            _buildCheckItem('개인 정보 정확성 확인'),
                            const SizedBox(height: 8),
                            _buildCheckItem('건물 관리자에게 문의'),
                          ],
                        ),
                      ),
                    const SizedBox(height: 32),

                    // 안내 텍스트
                    Text(
                      '문제가 계속되는 경우 고객센터에 문의해주세요.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF999999),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            // Footer Buttons
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  FilledButton(
                    onPressed: () {
                      context.goNamed('residentSignup');
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: const Color(0xFF006FFF),
                    ),
                    child: const Text('다시 신청하기'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: () {
                      context.go('/');
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(
                        color: Color(0xFFE8EEF2),
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      '뒤로 가기',
                      style: TextStyle(
                        color: Color(0xFF464A4D),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '✓',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF006FFF),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF464A4D),
            ),
          ),
        ),
      ],
    );
  }
}

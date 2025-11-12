import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ComplaintCompleteScreen extends StatelessWidget {
  const ComplaintCompleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 체크 아이콘
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFF006FFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // 완료 메시지
                    const Text(
                      '민원 등록 완료',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        fontSize: 28,
                        color: Color(0xFF17191A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 홈으로 이동 버튼
            Padding(
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    // 유저 대시보드로 이동
                    context.goNamed('userDashboard');
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF006FFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '홈으로 이동',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

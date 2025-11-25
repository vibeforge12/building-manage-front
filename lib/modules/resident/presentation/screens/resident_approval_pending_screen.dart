import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ResidentApprovalPendingScreen extends ConsumerStatefulWidget {
  const ResidentApprovalPendingScreen({super.key});

  @override
  ConsumerState<ResidentApprovalPendingScreen> createState() =>
      _ResidentApprovalPendingScreenState();
}

class _ResidentApprovalPendingScreenState
    extends ConsumerState<ResidentApprovalPendingScreen> {
  @override
  void initState() {
    super.initState();
    // 3초 후 자동으로 대시보드로 이동
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        print('⏳ PENDING 화면 표시 완료 - 대시보드로 이동');
        context.goNamed('userDashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Status Bar 영역 (높이 48)
            Container(
              height: 48,
              color: Colors.white,
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 40),

                    // 로딩 애니메이션 (Figma: Loading-circle 컴포넌트)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // 배경 원
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFF2F8FC),
                            ),
                          ),
                          // 로딩 애니메이션 (회전하는 그래디언트 원)
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color(0xFF006FFF).withValues(alpha: 0.7),
                              ),
                              strokeWidth: 3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 제목
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '관리자\n승인 대기중',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                          color: Color(0xFF17191A),
                          fontFamily: 'Pretendard',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 설명 텍스트
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '회원가입 승인 대기 중입니다.\n\n승인 시 입주민 서비스를 이용할 수 있습니다.',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.6,
                          color: Color(0xFF666666),
                          fontFamily: 'Pretendard',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 타이머 표시
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                '3초 후 자동으로 이동합니다...',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF999999),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

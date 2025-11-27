import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/shared/widgets/full_screen_image_background.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class HeadquartersDashboardScreen extends ConsumerWidget {
  const HeadquartersDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authNotifier = ref.read(authStateProvider.notifier);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 이미지
          const FullScreenImageBackground(assetPath: 'assets/headQuartersHome.png'),

          // 컨텐츠
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 버튼들 (마이페이지, 로그아웃)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // 마이페이지 버튼
                      IconButton(
                        onPressed: () {
                          context.push('/headquarters/profile');
                        },
                        icon: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      // 로그아웃 버튼
                      IconButton(
                        onPressed: () async {
                          await authNotifier.logout();
                          if (context.mounted) {
                            context.go('/');
                          }
                        },
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),

                  // 메인 제목
                  const Text(
                    '내 손안의 건물 파트너,',
                    style: TextStyle(
                      color: Color(0xffFFFFFF),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const Text(
                    '엄지 입니다.',
                    style: TextStyle(
                      color: Color(0xffFFFFFF),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 70),

                  // 관리자 계정발급 버튼
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        context.go('/headquarters/admin-account-issuance');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF006FFF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 72),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        '관리자 계정발급',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 하단 버튼들
                  Row(
                    children: [
                      // 관리자 버튼
                      Expanded(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context.push('/headquarters/manager-list');
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.person,
                                      color: Color(0xFF006FFF),
                                      size: 24,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '관리자',
                                      style: TextStyle(
                                        color: Color(0xff17191A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      // 건물 등록/관리 버튼
                      Expanded(
                        child: Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context.goNamed('managementSelection');
                              },
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.business,
                                      color: Color(0xFF006FFF),
                                      size: 24,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '건물 등록/관리',
                                      style: TextStyle(
                                        color: Color(0xff17191A),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textAlign: TextAlign.center,
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
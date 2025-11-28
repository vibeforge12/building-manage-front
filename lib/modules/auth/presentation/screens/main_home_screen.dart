import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/shared/widgets/full_screen_image_background.dart';
import 'package:building_manage_front/shared/widgets/page_header_text.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  void _openUserLogin(BuildContext context) {
    context.pushNamed('userLogin');
  }

  void _openAdminSelection(BuildContext context) {
    context.pushNamed('adminLoginSelection');
  }

  void _openSignUp(BuildContext context) {
    context.pushNamed('residentSignup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FullScreenImageBackground(assetPath: 'assets/home.png'),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _LandingHeader(),
                  const SizedBox(height: 60),
                  PrimaryActionButton(
                    label: '유저 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: Colors.black,
                    onPressed: () => _openUserLogin(context),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '관리자 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: Colors.black,
                    onPressed: () => _openAdminSelection(context),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Color(0xffBBC5CC),
                          thickness: 1,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '또는',
                          style: TextStyle(
                            color: Color(0xffBBC5CC),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Color(0xffBBC5CC),
                          thickness: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '회원가입',
                    backgroundColor: const Color(0xFF006FFF),
                    foregroundColor: Colors.white,
                    onPressed: () => context.go('/resident-signup'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LandingHeader extends StatelessWidget {
  const _LandingHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Transform.translate(
          offset: const Offset(-40, 0),
          child: Image.asset(
            'assets/splash/whiteLogo.png',
            height: 200,
          ),
        ),
        Text(
          '안녕하세요 \n엄지 입니다.',
          textAlign: TextAlign.left,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}


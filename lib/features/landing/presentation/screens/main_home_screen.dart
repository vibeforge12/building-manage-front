import 'package:flutter/material.dart';

import 'package:building_manage_front/features/auth/presentation/screens/admin_login_selection_screen.dart';
import 'package:building_manage_front/features/auth/presentation/screens/user_login_screen.dart';
import 'package:building_manage_front/features/common/presentation/widgets/full_screen_image_background.dart';
import 'package:building_manage_front/features/common/presentation/widgets/page_header_text.dart';
import 'package:building_manage_front/features/common/presentation/widgets/primary_action_button.dart';
import 'package:building_manage_front/features/registration/presentation/screens/sign_up_screen.dart';

class MainHomeScreen extends StatelessWidget {
  const MainHomeScreen({super.key});

  void _openUserLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const UserLoginScreen()));
  }

  void _openAdminSelection(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminLoginSelectionScreen()),
    );
  }

  void _openSignUp(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _LandingHeader(),
                  const Spacer(),
                  PrimaryActionButton(
                    label: '유저 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: const Color(0xFF006FFF),
                    onPressed: () => _openUserLogin(context),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '관리자 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: const Color(0xFF006FFF),
                    onPressed: () => _openAdminSelection(context),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '회원가입',
                    backgroundColor: const Color(0xFF006FFF),
                    foregroundColor: Colors.white,
                    onPressed: () => _openSignUp(context),
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
        const PageHeaderText('빌딩 관리 시스템'),
        const SizedBox(height: 8),
        Text(
          '하나의 앱에서 본사부터 입주자까지 연결되는\n통합 관리 경험을 시작하세요.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }
}

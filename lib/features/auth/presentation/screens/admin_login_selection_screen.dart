import 'package:flutter/material.dart';

import 'package:building_manage_front/features/auth/presentation/screens/headquarters_login_screen.dart';
import 'package:building_manage_front/features/auth/presentation/screens/manager_staff_login_screen.dart';
import 'package:building_manage_front/features/common/presentation/widgets/full_screen_image_background.dart';
import 'package:building_manage_front/features/common/presentation/widgets/page_header_text.dart';
import 'package:building_manage_front/features/common/presentation/widgets/primary_action_button.dart';

class AdminLoginSelectionScreen extends StatelessWidget {
  const AdminLoginSelectionScreen({super.key});

  void _openHeadquartersLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HeadquartersLoginScreen()));
  }

  void _openManagerStaffLogin(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ManagerStaffLoginScreen()));
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
                  const PageHeaderText('관리자 로그인'),
                  const SizedBox(height: 8),
                  Text(
                    '본사와 건물 현장 담당자를 구분해 로그인하세요.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  PrimaryActionButton(
                    label: '본사 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: const Color(0xFF006FFF),
                    onPressed: () => _openHeadquartersLogin(context),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '관리자/담당자 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: const Color(0xFF006FFF),
                    onPressed: () => _openManagerStaffLogin(context),
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

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:building_manage_front/shared/widgets/full_screen_image_background.dart';
import 'package:building_manage_front/shared/widgets/page_header_text.dart';
import 'package:building_manage_front/shared/widgets/primary_action_button.dart';

class AdminLoginSelectionScreen extends StatelessWidget {
  const AdminLoginSelectionScreen({super.key});

  void _openHeadquartersLogin(BuildContext context) {
    context.pushNamed('headquartersLogin');
  }

  void _openAdminLogin(BuildContext context) {
    context.pushNamed('adminLogin');
  }

  void _openManagerLogin(BuildContext context) {
    context.pushNamed('managerLogin');
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
                children: [
                  Row(
                    children: [
                      Text(
                        '관리자님 어서오세요',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w700
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 60),
                  PrimaryActionButton(
                    label: '본사 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: Colors.black,
                    onPressed: () => _openHeadquartersLogin(context),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '관리자 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: Colors.black,
                    onPressed: () => _openAdminLogin(context),
                  ),
                  const SizedBox(height: 16),
                  PrimaryActionButton(
                    label: '담당자 로그인',
                    backgroundColor: const Color(0xFFEDF9FF),
                    foregroundColor: Colors.black,
                    onPressed: () => _openManagerLogin(context),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/presentation/auth/providers/signup_form_provider.dart';
import 'package:building_manage_front/presentation/auth/widgets/resident_signup_step1.dart';
import 'package:building_manage_front/presentation/auth/widgets/resident_signup_step2.dart';

import '../../../common/widget/appBar.dart';

class ResidentSignupScreen extends ConsumerWidget {
  const ResidentSignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(signupFormProvider);
    final formNotifier = ref.read(signupFormProvider.notifier);

    return Scaffold(
      appBar: commonAppBar('입주민 회원가입'),
      body: Column(
        children: [
          // Form content
          Expanded(
            child: formState.currentStep == 1
                ? ResidentSignupStep1(
                    onNext: () {
                      formNotifier.nextStep();
                    },
                  )
                : ResidentSignupStep2(
                    onPrevious: () {
                      formNotifier.previousStep();
                    },
                    onComplete: () {
                      // TODO: API 호출 및 회원가입 완료 처리
                      _showCompletionDialog(context);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showCompletionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('구현 대기 중'),
        content: const Text('2단계 폼 구현이 완료되면\n회원가입을 진행할 수 있습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
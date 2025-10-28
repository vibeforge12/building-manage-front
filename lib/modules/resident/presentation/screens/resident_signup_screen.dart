import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/signup_form_provider.dart';
import '../widgets/resident_signup_step1.dart';
import '../widgets/resident_signup_step2.dart';
import '../widgets/resident_signup_step3.dart';
import '../../data/datasources/resident_auth_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/appBar.dart';

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
                : formState.currentStep == 2
                    ? ResidentSignupStep2(
                        onPrevious: () {
                          formNotifier.previousStep();
                        },
                        onComplete: () {
                          formNotifier.nextStep();
                        },
                      )
                    : ResidentSignupStep3(
                        onPrevious: () {
                          formNotifier.previousStep();
                        },
                        onComplete: () {
                          _submitSignup(context, ref);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitSignup(BuildContext context, WidgetRef ref) async {
    try {
      // 로딩 다이얼로그 표시
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('회원가입 중...'),
            ],
          ),
        ),
      );

      final formData = ref.read(signupFormProvider);
      final authDataSource = ref.read(residentAuthRemoteDataSourceProvider);

      // API 호출
      await authDataSource.register(
        username: formData.username!,
        password: formData.password!,
        name: formData.name!,
        phoneNumber: formData.phoneNumber!,
        dong: formData.dong!,
        hosu: formData.hosu!,
        buildingId: formData.buildingId!,
      );

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
        _showSuccessDialog(context, ref);
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
        _showErrorDialog(context, e.toString());
      }
    }
  }

  void _showSuccessDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('회원가입 완료'),
        content: const Text('회원가입이 성공적으로 완료되었습니다.\n로그인 화면으로 이동합니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(signupFormProvider.notifier).reset();
              context.go('/user-login');
            },
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error, color: Colors.red, size: 48),
        title: const Text('회원가입 실패'),
        content: Text(errorMessage),
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
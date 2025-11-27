import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/signup_form_provider.dart';
import '../providers/resident_providers.dart';
import '../widgets/resident_signup_consent.dart';
import '../widgets/resident_signup_step1.dart';
import '../widgets/resident_signup_step2.dart';
import '../widgets/resident_signup_step3.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class ResidentSignupScreen extends ConsumerWidget {
  const ResidentSignupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formState = ref.watch(signupFormProvider);
    final formNotifier = ref.read(signupFormProvider.notifier);

    // Step 1(약관 동의)에서는 앱바 없이 표시
    if (formState.currentStep == 1) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: _buildCurrentStep(context, ref, formState, formNotifier),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            formNotifier.previousStep();
          },
        ),
        title: const Text(
          '입주민 회원가입',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
          ),
        ),
      ),
      body: Column(
        children: [
          // Form content - 4단계로 변경
          Expanded(
            child: _buildCurrentStep(context, ref, formState, formNotifier),
          ),
        ],
      ),
    );
  }

  /// 현재 단계에 맞는 위젯 반환 (4단계)
  Widget _buildCurrentStep(
    BuildContext context,
    WidgetRef ref,
    SignupFormState formState,
    SignupFormNotifier formNotifier,
  ) {
    switch (formState.currentStep) {
      case 1:
        // Step 1: 약관 동의 (신규)
        return ResidentSignupConsent(
          onNext: () {
            formNotifier.nextStep();
          },
        );
      case 2:
        // Step 2: 동/호수, 아이디, 비밀번호 (기존 Step 1)
        return ResidentSignupStep1(
          onNext: () {
            formNotifier.nextStep();
          },
        );
      case 3:
        // Step 3: 건물 선택 (기존 Step 2)
        return ResidentSignupStep2(
          onPrevious: () {
            formNotifier.previousStep();
          },
          onComplete: () {
            formNotifier.nextStep();
          },
        );
      case 4:
        // Step 4: 이름, 휴대폰 번호 (기존 Step 3)
        return ResidentSignupStep3(
          onPrevious: () {
            formNotifier.previousStep();
          },
          onComplete: () {
            _submitSignup(context, ref);
          },
        );
      default:
        return const SizedBox.shrink();
    }
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

      // UseCase를 통한 회원가입 (비즈니스 로직 포함)
      final registerUseCase = ref.read(registerResidentUseCaseProvider);
      await registerUseCase.execute(
        username: formData.username!,
        password: formData.password!,
        name: formData.name!,
        phoneNumber: formData.phoneNumber!,
        dong: formData.dong!,
        ho: formData.hosu!,
        buildingId: formData.buildingId!,
      );

      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
        await _showSuccessDialog(context, ref);
      }
    } catch (e) {
      // 로딩 다이얼로그 닫기
      if (context.mounted) {
        Navigator.of(context).pop();
        await _showErrorDialog(context, ref, e.toString());
      }
    }
  }

  Future<void> _showSuccessDialog(BuildContext context, WidgetRef ref) async {
    await showCustomConfirmationDialog(
      context: context,
      title: '회원가입 완료',
      content: const Text(
        '회원가입이 성공적으로 완료되었습니다.',
        style: TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      confirmText: '확인',
      cancelText: '',
      barrierDismissible: false,
      confirmOnLeft: true,
    );

    if (context.mounted) {
      ref.read(signupFormProvider.notifier).reset();
      context.go('/user-login');
    }
  }

  Future<void> _showErrorDialog(BuildContext context, WidgetRef ref, String errorMessage) async {
    await showCustomConfirmationDialog(
      context: context,
      title: '회원가입 실패',
      content: Text(
        errorMessage,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
      ),
      confirmText: '확인',
      cancelText: '',
      isDestructive: true,
      barrierDismissible: false,
      confirmOnLeft: true,
    );

    if (context.mounted) {
      // 에러 다이얼로그 닫을 때 폼 상태 reset (Step 1로 돌아가기)
      ref.read(signupFormProvider.notifier).reset();
    }
  }
}
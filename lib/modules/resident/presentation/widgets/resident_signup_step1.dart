import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signup_form_provider.dart';
import 'package:building_manage_front/shared/widgets/fieldLable.dart';
import 'package:building_manage_front/shared/widgets/signUp.dart';

class ResidentSignupStep1 extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ResidentSignupStep1({
    super.key,
    required this.onNext,
  });

  @override
  ConsumerState<ResidentSignupStep1> createState() => _ResidentSignupStep1State();
}

class _ResidentSignupStep1State extends ConsumerState<ResidentSignupStep1> {
  final _formKey = GlobalKey<FormState>();
  final _dongController = TextEditingController();
  final _hosuController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    // 기존 데이터가 있다면 컨트롤러에 설정
    final formData = ref.read(signupFormProvider);
    _dongController.text = formData.dong ?? '';
    _hosuController.text = formData.hosu ?? '';
    _passwordController.text = formData.password ?? '';
    _passwordConfirmController.text = formData.passwordConfirm ?? '';
  }

  @override
  void dispose() {
    _dongController.dispose();
    _hosuController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      // 폼 데이터를 상태에 저장
      ref.read(signupFormProvider.notifier).updateStep1Data(
        dong: _dongController.text,
        hosu: _hosuController.text,
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
      );

      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.white, // ✅ 전체 배경 흰색
      padding: const EdgeInsets.all(24.0), // ✅ 내부 여백 유지
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 동 입력
            CommonInputField(
              label: '동',
              hint: '예: 101동',
              controller: _dongController,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '동을 입력해주세요';
                }
                if (!RegExp(r'^\d+동?$').hasMatch(value.trim())) {
                  return '올바른 동 형식을 입력해주세요 (예: 101동)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 호수 입력
            CommonInputField(
              label: '호수',
              hint: '예: 1001호',
              controller: _hosuController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '호수를 입력해주세요';
                }
                if (!RegExp(r'^\d+호?$').hasMatch(value.trim())) {
                  return '올바른 호수 형식을 입력해주세요 (예: 1001호)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 비밀번호 입력
            CommonInputField(
              label: '비밀번호',
              hint: '8자 이상 입력해주세요',
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              showVisibilityToggle: true,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호를 입력해주세요';
                }
                if (value.length < 8) {
                  return '비밀번호는 8자 이상이어야 합니다';
                }
                if (!RegExp(r'^(?=.*[a-zA-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])')
                    .hasMatch(value)) {
                  return '영문, 숫자, 특수문자를 포함해야 합니다';
                }
                return null;
              },
              onChanged: (value) {
                if (_passwordConfirmController.text.isNotEmpty) {
                  setState(() {
                    _formKey.currentState?.validate();
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // 비밀번호 재확인 입력
            CommonInputField(
              label: '비밀번호 재확인',
              hint: '비밀번호를 다시 입력해주세요',
              controller: _passwordConfirmController,
              obscureText: !_isPasswordConfirmVisible,
              showVisibilityToggle: true,
              onToggleVisibility: () {
                setState(() {
                  _isPasswordConfirmVisible = !_isPasswordConfirmVisible;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '비밀번호 확인을 입력해주세요';
                }
                if (value != _passwordController.text) {
                  return '비밀번호가 일치하지 않습니다';
                }
                return null;
              },
              onFieldSubmitted: (_) => _handleNext(),
            ),
            const SizedBox(height: 32),

            // 다음 단계 버튼
            ElevatedButton(
              onPressed: _handleNext,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: Color(0xffE8EEF2)
              ),
              child: const Text(
                '다음',
                style: TextStyle(
                  color: Color(0xffA4ADB2),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
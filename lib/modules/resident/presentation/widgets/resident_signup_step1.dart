import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signup_form_provider.dart';
import 'package:building_manage_front/shared/widgets/sign_up.dart';

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
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isPasswordConfirmVisible = false;

  // 다음 버튼 활성화 여부 확인
  bool get _isFormValid {
    return _dongController.text.trim().isNotEmpty &&
        _hosuController.text.trim().isNotEmpty &&
        _usernameController.text.trim().isNotEmpty &&
        _passwordController.text.isNotEmpty &&
        _passwordConfirmController.text.isNotEmpty &&
        (_formKey.currentState?.validate() ?? false);
  }

  @override
  void initState() {
    super.initState();
    // 기존 데이터가 있다면 컨트롤러에 설정
    final formData = ref.read(signupFormProvider);
    _dongController.text = formData.dong ?? '';
    _hosuController.text = formData.hosu ?? '';
    _passwordController.text = formData.password ?? '';
    _passwordConfirmController.text = formData.passwordConfirm ?? '';
    _usernameController.text = formData.username ?? '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 화면이 다시 표시될 때 상태 업데이트 (이전 단계로 돌아올 때)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _dongController.dispose();
    _hosuController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

// ResidentSignupStep1.dart
  void _handleNext() {
    if (_formKey.currentState?.validate() ?? false) {
      // ✅ username 포함하여 1단계 데이터 저장
      ref.read(signupFormProvider.notifier).updateStep1Data(
        username: _usernameController.text,
        dong: _dongController.text,
        hosu: _hosuController.text,
        password: _passwordController.text,
        passwordConfirm: _passwordConfirmController.text,
      );

      // ✅ 여기서 username을 다시 updateStep2Data로 넣지 않습니다 (중복/충돌 방지)
      // ref.read(signupFormProvider.notifier).updateStep2Data(...);  // 제거

      widget.onNext();
    }
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: Colors.white, 
      padding: const EdgeInsets.all(24.0),
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
              onChanged: (_) => setState(() {}),
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
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // 아이디 입력
            CommonInputField(
              label: '아이디',
              hint: '이메일을 입력 해주세요',
              controller: _usernameController,
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '아이디를 입력해주세요';
                }
                final v = value.trim();
                if (!RegExp(r'^[a-zA-Z0-9_]{4,20}$').hasMatch(v)) {
                  return '영문/숫자/언더스코어 4~20자로 입력해주세요';
                }
                return null;
              },
              onChanged: (_) => setState(() {}),
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
                setState(() {
                  _formKey.currentState?.validate();
                });
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
              onChanged: (_) => setState(() {}),
              onFieldSubmitted: (_) => _isFormValid ? _handleNext() : null,
            ),
            const SizedBox(height: 32),

            // 다음 단계 버튼
            ElevatedButton(
              onPressed: _isFormValid ? _handleNext : null,
              style: ElevatedButton.styleFrom(
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                backgroundColor: _isFormValid ? const Color(0xFF006FFF) : const Color(0xFFE8EEF2),
                disabledBackgroundColor: const Color(0xFFE8EEF2),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  color: _isFormValid ? Colors.white : const Color(0xFFA4ADB2),
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

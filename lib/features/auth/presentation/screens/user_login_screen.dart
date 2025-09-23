import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:building_manage_front/features/common/presentation/widgets/page_header_text.dart';
import 'package:building_manage_front/features/registration/presentation/screens/sign_up_screen.dart';

class UserLoginScreen extends StatefulWidget {
  const UserLoginScreen({super.key});

  @override
  State<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends State<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dongController = TextEditingController();
  final _hoController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loginFailed = false;

  @override
  void dispose() {
    _dongController.dispose();
    _hoController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptLogin() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _loginFailed = false);
      return;
    }
    FocusScope.of(context).unfocus();

    const demoPassword = '1234';
    final isSuccess = _passwordController.text.trim() == demoPassword;

    setState(() => _loginFailed = !isSuccess);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인 성공 (stub). 백엔드 연동 시 교체 예정입니다.')),
      );
    }
  }

  void _recoverPassword() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('비밀번호 찾기 흐름은 아직 구현되지 않았습니다.')));
  }

  void _openSignUp() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SignUpScreen()));
  }

  // 공통 입력 스타일
  InputDecoration _filledInput(String hint) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
      ),
      isDense: true,
      filled: true,
      fillColor: theme.colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.error, width: 1.5),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const PageHeaderText('로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 동
                _fieldLabel('동'),
                TextFormField(
                  controller: _dongController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _filledInput('동을 입력해주세요.'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '동 정보를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),

                // 호수
                _fieldLabel('호수'),
                TextFormField(
                  controller: _hoController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: _filledInput('호수를 입력해주세요.'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '호수를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),

                // 비밀번호
                _fieldLabel('비밀번호'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: _filledInput('비밀번호를 입력해주세요.'),
                  onFieldSubmitted: (_) => _attemptLogin(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? '비밀번호를 입력해 주세요.' : null,
                ),

                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _loginFailed
                      ? Padding(
                          key: const ValueKey('loginError'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '아이디 또는 비밀번호가 잘못 되었습니다. 아이디와 비밀번호를 정확히 입력해 주세요.',
                              textAlign: TextAlign.left,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('noError')),
                ),
                const SizedBox(height: 8),

                Align(
                  alignment: Alignment.center,
                  child: RichText(
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium,
                      children: [
                        const TextSpan(text: '비밀번호를 잊으셨나요? '),
                        TextSpan(
                          text: '비밀번호 찾기',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF006FFF),
                            fontWeight: FontWeight.w700,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = _recoverPassword,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 버튼들
                FilledButton.tonal(
                  onPressed: _attemptLogin, // 로직 변경 없음
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xFFE8EEF2),
                  ),
                  child: const Text('로그인'),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _openSignUp,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xFF006FFF),
                  ),
                  child: const Text('회원가입'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

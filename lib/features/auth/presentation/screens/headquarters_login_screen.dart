import 'package:flutter/material.dart';

import 'package:building_manage_front/features/common/presentation/widgets/page_header_text.dart';

class HeadquartersLoginScreen extends StatefulWidget {
  const HeadquartersLoginScreen({super.key});

  @override
  State<HeadquartersLoginScreen> createState() =>
      _HeadquartersLoginScreenState();
}

class _HeadquartersLoginScreenState extends State<HeadquartersLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loginFailed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _attemptLogin() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _loginFailed = false);
      return;
    }

    FocusScope.of(context).unfocus();

    const demoEmail = 'hq@example.com';
    const demoPassword = 'hq1234';

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final isSuccess = email == demoEmail && password == demoPassword;

    setState(() => _loginFailed = !isSuccess);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공 (stub). 백엔드 연동 시 실제 검증으로 대체 예정입니다.'),
        ),
      );
    }
  }

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
                _fieldLabel('이메일'),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  decoration: _filledInput('이메일을 입력해 주세요.'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '이메일을 입력해 주세요.';
                    }
                    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    if (!emailPattern.hasMatch(value.trim())) {
                      return '올바른 이메일 형식이 아닙니다.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _fieldLabel('비밀번호'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  decoration: _filledInput('비밀번호를 입력해 주세요.'),
                  onFieldSubmitted: (_) => _attemptLogin(),
                  validator: (value) => (value == null || value.isEmpty)
                      ? '비밀번호를 입력해 주세요.'
                      : null,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _loginFailed
                      ? Padding(
                          key: const ValueKey('hqLoginError'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            '이메일 또는 비밀번호가 잘못 되었습니다.\n정확한 정보를 입력해 주세요.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('hqLoginOk')),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _attemptLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xff006FFF)
                  ),
                  child: const Text('로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

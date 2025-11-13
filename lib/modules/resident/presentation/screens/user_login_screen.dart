import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/resident/presentation/providers/resident_providers.dart';

import 'package:building_manage_front/shared/widgets/page_header_text.dart';
import 'package:building_manage_front/shared/widgets/field_label.dart';
class UserLoginScreen extends ConsumerStatefulWidget {
  const UserLoginScreen({super.key});

  @override
  ConsumerState<UserLoginScreen> createState() => _UserLoginScreenState();
}

class _UserLoginScreenState extends ConsumerState<UserLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loginFailed = false;
  bool _loading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _loginFailed = false);
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _loading = true; _loginFailed = false; });

    try {
      // UseCase를 통한 로그인 (비즈니스 로직 포함)
      final loginUseCase = ref.read(loginResidentUseCaseProvider);
      final res = await loginUseCase.execute(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      final data = res['data'] ?? res;
      final accessToken = data['accessToken'] as String?;
      final user = data['user'] as Map<String, dynamic>?;
      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('토큰이 응답에 없습니다.');
      }

      await ref.read(authStateProvider.notifier).loginSuccess(
        user ?? <String, dynamic>{},
        accessToken,
      );

      if (mounted) context.goNamed('userDashboard');
    } catch (e) {
      setState(() => _loginFailed = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('로그인 실패: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _recoverPassword() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('비밀번호 찾기 흐름은 아직 구현되지 않았습니다.')));
  }

  void _openSignUp() {
    context.pushNamed('residentSignup');
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
      fillColor: Colors.white,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const PageHeaderText('입주민 로그인'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 아이디
                fieldLabel('아이디', context),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  decoration: _filledInput('아이디를 입력해주세요.'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '아이디를 입력해 주세요.' : null,
                ),
                const SizedBox(height: 16),

                // 비밀번호
                fieldLabel('비밀번호', context),
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
                  onPressed: _loading ? null : _attemptLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xFFE8EEF2),
                  ),
                  child: _loading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('로그인'),
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

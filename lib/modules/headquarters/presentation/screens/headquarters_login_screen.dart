import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class HeadquartersLoginScreen extends ConsumerStatefulWidget {
  const HeadquartersLoginScreen({super.key});

  @override
  ConsumerState<HeadquartersLoginScreen> createState() =>
      _HeadquartersLoginScreenState();
}

class _HeadquartersLoginScreenState extends ConsumerState<HeadquartersLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _attemptLogin() async {
    if (!_formKey.currentState!.validate()) {
      setState(() => _errorMessage = null);
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authDataSource = ref.read(authRemoteDataSourceProvider);
      final authNotifier = ref.read(authStateProvider.notifier);

      final response = await authDataSource.loginHeadquarters(
        username: _usernameController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 사용자 정보 설정
      final userData = response['data'];
      if (userData != null) {
        await authNotifier.loginSuccess(
          userData['user'],
          userData['accessToken'],
        );

        if (mounted) {
          // ScaffoldMessenger.of(context).showSnackBar(
          //   const SnackBar(
          //     content: Text('본사 로그인 성공!'),
          //     backgroundColor: Colors.green,
          //   ),
          // );

          // 본사 대시보드로 이동
          context.goNamed('headquartersDashboard');
        }
      }
    } catch (e) {
      String errorMessage = '로그인 중 오류가 발생했습니다.';

      if (e is ApiException) {
        errorMessage = e.userFriendlyMessage;
      }

      setState(() => _errorMessage = errorMessage);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
      fillColor: const Color(0xFFF8F9FA),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          '로그인',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Color(0xFF464A4D),
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFE8EEF2),
            // margin: EdgeInsets.zero,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _fieldLabel('사용자명'),
                TextFormField(
                  controller: _usernameController,
                  keyboardType: TextInputType.text,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                  decoration: _filledInput('사용자명을 입력해 주세요.'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '사용자명을 입력해 주세요.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _fieldLabel('비밀번호'),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  enabled: !_isLoading,
                  textInputAction: TextInputAction.done,
                  decoration: _filledInput('비밀번호를 입력해 주세요.'),
                  onFieldSubmitted: (_) => _attemptLogin(),
                  validator: (value) => (value == null || value.isEmpty)
                      ? '비밀번호를 입력해 주세요.'
                      : null,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _errorMessage != null
                      ? Padding(
                          key: const ValueKey('hqLoginError'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('hqLoginOk')),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _isLoading ? null : _attemptLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xff006FFF)
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('로그인'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

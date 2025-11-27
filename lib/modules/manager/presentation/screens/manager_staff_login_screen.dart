import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/page_header_text.dart';

class ManagerStaffLoginScreen extends ConsumerStatefulWidget {
  const ManagerStaffLoginScreen({super.key});

  @override
  ConsumerState<ManagerStaffLoginScreen> createState() =>
      _ManagerStaffLoginScreenState();
}

class _ManagerStaffLoginScreenState extends ConsumerState<ManagerStaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _loginFailed = false;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
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
      final authDataSource = ref.read(authRemoteDataSourceProvider);
      final result = await authDataSource.loginStaff(
        staffCode: _codeController.text.trim(),
      );

      final data = result['data'] ?? result;
      final accessToken = data['accessToken'] as String?;
      final userData = data['user'] as Map<String, dynamic>?;

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('토큰이 응답에 없습니다.');
      }

      // AuthState 갱신
      await ref.read(authStateProvider.notifier).loginSuccess(
        userData ?? <String, dynamic>{},
        accessToken,
      );

      if (mounted) {
        context.goNamed('managerDashboard');
      }
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
        title: const PageHeaderText('로그인'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '담당자 코드',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    hintText: '담당자 코드를 입력하세요.',
                    isDense: true,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.error,
                        width: 1.5,
                      ),
                    ),
                  ),
                  onFieldSubmitted: (_) => _attemptLogin(),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? '코드를 입력해 주세요.'
                      : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: _loginFailed
                        ? Padding(
                            key: const ValueKey('staffCodeError'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '담당자 코드가 잘못 되었습니다.\n담당자 코드를 정확히 입력해 주세요.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('staffCodeOk')),
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _loading ? null : _attemptLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: Color(0xff006FFF)
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/shared/widgets/page_header_text.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';
import 'package:building_manage_front/core/network/exceptions/api_exception.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
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

      final response = await authDataSource.loginManager(
        managerCode: _codeController.text.trim(),
      );

      // 응답 payload 추출 및 관리자 역할 정규화(기존 동작 복원)
      final payload = response['data'] ?? response;
      final accessToken = payload['accessToken'];
      final refreshToken = payload['refreshToken'];
      final userJson = Map<String, dynamic>.from(payload['user'] ?? {});
      userJson['role'] = 'admin';

      if (accessToken is String && accessToken.isNotEmpty && userJson.isNotEmpty) {
        await authNotifier.loginSuccess(userJson, accessToken, refreshToken);

        if (mounted) {
          context.goNamed('adminDashboard');
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
                  '관리자 코드',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _codeController,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: '관리자 코드를 입력하세요.',
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
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _errorMessage != null
                      ? Padding(
                          key: const ValueKey('adminCodeError'),
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(key: ValueKey('adminCodeOk')),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _isLoading ? null : _attemptLogin,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color(0xff006FFF),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
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

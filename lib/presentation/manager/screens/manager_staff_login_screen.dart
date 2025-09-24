import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:building_manage_front/presentation/common/widgets/page_header_text.dart';

class ManagerStaffLoginScreen extends StatefulWidget {
  const ManagerStaffLoginScreen({super.key});

  @override
  State<ManagerStaffLoginScreen> createState() =>
      _ManagerStaffLoginScreenState();
}

class _ManagerStaffLoginScreenState extends State<ManagerStaffLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _loginFailed = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _attemptLogin() {
    if (!_formKey.currentState!.validate()) {
      setState(() => _loginFailed = false);
      return;
    }

    FocusScope.of(context).unfocus();

    const demoManagerCode = 'MANAGER1234';
    final isSuccess = _codeController.text.trim() == demoManagerCode;

    setState(() => _loginFailed = !isSuccess);

    if (isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('로그인 성공 (stub). 백엔드 연동 시 실제 검증으로 대체 예정입니다.'),
        ),
      );

      // 임시로 매니저 대시보드로 이동 (추후 인증 시스템과 연동)
      context.goNamed('managerDashboard');
    }
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
                  decoration: InputDecoration(
                    hintText: '관리자 코드를 입력하세요.',
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surface,
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
                            key: const ValueKey('managerCodeError'),
                            padding: const EdgeInsets.only(top: 12),
                            child: Text(
                              '관리자 코드가 잘못 되었습니다.\n관리자 코드를 정확히 입력해 주세요.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.error,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(key: ValueKey('managerCodeOk')),
                  ),
                ),
                const Spacer(),
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

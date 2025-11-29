import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/resident/data/datasources/resident_auth_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class NewPasswordResetScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String code;

  const NewPasswordResetScreen({
    super.key,
    required this.phoneNumber,
    required this.code,
  });

  @override
  ConsumerState<NewPasswordResetScreen> createState() => _NewPasswordResetScreenState();
}

class _NewPasswordResetScreenState extends ConsumerState<NewPasswordResetScreen> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isObscuredPassword = true;
  bool _isObscuredConfirmPassword = true;
  bool _isResettingPassword = false;

  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    // 입력 검증
    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

    bool isValid = true;

    if (_passwordController.text.trim().isEmpty) {
      setState(() {
        _passwordError = '새 비밀번호를 입력해주세요.';
      });
      isValid = false;
    }

    if (_confirmPasswordController.text.trim().isEmpty) {
      setState(() {
        _confirmPasswordError = '비밀번호 확인을 입력해주세요.';
      });
      isValid = false;
    }

    if (isValid && _passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _confirmPasswordError = '비밀번호가 일치하지 않습니다.';
      });
      isValid = false;
    }

    if (!isValid) return;

    setState(() {
      _isResettingPassword = true;
    });

    try {
      final dataSource = ref.read(residentAuthRemoteDataSourceProvider);
      await dataSource.resetPassword(
        phoneNumber: widget.phoneNumber,
        code: widget.code,
        newPassword: _passwordController.text.trim(),
      );

      if (mounted) {
        await showCustomConfirmationDialog(
          context: context,
          title: '',
          content: const Text(
            '비밀번호 재설정이 완료되었습니다.',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          confirmText: '확인',
          cancelText: '',
          barrierDismissible: false,
          confirmOnLeft: true,
        );

        if (mounted) {
          // 로그인 화면으로 이동
          context.go('/user-login');
        }
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('비밀번호 재설정 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResettingPassword = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // 안내 텍스트
                      const Text(
                        '새로운 비밀번호를 입력해주세요',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF17191A),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 새 비밀번호 입력
                      _buildLabel('새 비밀번호'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _passwordController,
                        hintText: '새 비밀번호를 입력하세요',
                        errorText: _passwordError,
                        isObscured: _isObscuredPassword,
                        onToggle: () {
                          setState(() {
                            _isObscuredPassword = !_isObscuredPassword;
                          });
                        },
                      ),

                      const SizedBox(height: 24),

                      // 비밀번호 확인
                      _buildLabel('비밀번호 확인'),
                      const SizedBox(height: 8),
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        hintText: '비밀번호를 다시 입력하세요',
                        errorText: _confirmPasswordError,
                        isObscured: _isObscuredConfirmPassword,
                        onToggle: () {
                          setState(() {
                            _isObscuredConfirmPassword = !_isObscuredConfirmPassword;
                          });
                        },
                      ),

                      const SizedBox(height: 32),

                      // 확인 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: FilledButton(
                          onPressed: _isResettingPassword ? null : _resetPassword,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF006FFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: _isResettingPassword
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  '확인',
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    height: 1.5,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Color(0xFFE8EEF2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: () => context.pop(),
            padding: const EdgeInsets.all(12),
          ),
          const Expanded(
            child: Center(
              child: Text(
                '비밀번호 재설정',
                style: TextStyle(
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Color(0xFF17191A),
                ),
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'Pretendard',
        fontWeight: FontWeight.w700,
        fontSize: 14,
        color: Color(0xFF17191A),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hintText,
    String? errorText,
    required bool isObscured,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF2F8FC),
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1)
                : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscured,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF17191A),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF757B80),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscured ? Icons.visibility_off : Icons.visibility,
                  color: const Color(0xFF757B80),
                  size: 20,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Text(
              errorText,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ),
      ],
    );
  }
}

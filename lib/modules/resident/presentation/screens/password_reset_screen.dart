import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/resident/data/datasources/resident_auth_remote_datasource.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';

class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _usernameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  bool _isRequestingCode = false;
  bool _isVerifyingCode = false;
  bool _codeSent = false;

  String? _usernameError;
  String? _phoneNumberError;
  String? _verificationCodeError;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneNumberController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _requestVerificationCode() async {
    // 입력 검증
    setState(() {
      _usernameError = null;
      _phoneNumberError = null;
    });

    bool isValid = true;

    if (_usernameController.text.trim().isEmpty) {
      setState(() {
        _usernameError = '아이디를 입력해주세요.';
      });
      isValid = false;
    }

    if (_phoneNumberController.text.trim().isEmpty) {
      setState(() {
        _phoneNumberError = '휴대폰 번호를 입력해주세요.';
      });
      isValid = false;
    }

    if (!isValid) return;

    setState(() {
      _isRequestingCode = true;
    });

    try {
      final dataSource = ref.read(residentAuthRemoteDataSourceProvider);
      await dataSource.requestPasswordReset(
        username: _usernameController.text.trim(),
        phoneNumber: _phoneNumberController.text.replaceAll(RegExp(r'[^0-9]'), ''),
      );

      setState(() {
        _codeSent = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('인증번호가 발송되었습니다.'),
            backgroundColor: Color(0xFF006FFF),
          ),
        );
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('USER_NOT_FOUND')) {
        setState(() {
          _usernameError = '일치하는 사용자 정보가 없습니다.';
        });
      } else if (errorMessage.contains('INVALID_REQUEST')) {
        setState(() {
          _phoneNumberError = '휴대폰 번호를 확인해주세요.';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('인증번호 발송 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRequestingCode = false;
        });
      }
    }
  }

  Future<void> _verifyCode() async {
    setState(() {
      _verificationCodeError = null;
    });

    if (_verificationCodeController.text.trim().isEmpty) {
      setState(() {
        _verificationCodeError = '인증번호를 입력해주세요.';
      });
      return;
    }

    setState(() {
      _isVerifyingCode = true;
    });

    try {
      final dataSource = ref.read(residentAuthRemoteDataSourceProvider);
      final response = await dataSource.verifyPasswordReset(
        phoneNumber: _phoneNumberController.text.replaceAll(RegExp(r'[^0-9]'), ''),
        code: _verificationCodeController.text.trim(),
      );

      final verified = response['verified'] as bool? ?? false;

      if (verified) {
        if (mounted) {
          await showCustomConfirmationDialog(
            context: context,
            title: '',
            content: const Text(
              '인증이 완료되었습니다.',
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
            context.pop();
          }
        }
      }
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('INVALID_CODE')) {
        setState(() {
          _verificationCodeError = '유효하지 않거나 만료된 인증번호입니다.';
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('인증 실패: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isVerifyingCode = false;
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
                        '비밀번호를 찾을 아이디를 입력해주세요',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: Color(0xFF17191A),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 아이디 입력
                      _buildLabel('아이디'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _usernameController,
                        hintText: '아이디를 입력하세요',
                        errorText: _usernameError,
                        enabled: !_codeSent,
                      ),

                      const SizedBox(height: 24),

                      // 휴대폰 번호 입력 + 받기 버튼
                      _buildLabel('휴대폰 번호'),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _phoneNumberController,
                              hintText: '휴대폰 번호를 입력하세요',
                              keyboardType: TextInputType.phone,
                              errorText: _phoneNumberError,
                              enabled: !_codeSent,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: (_isRequestingCode || _codeSent)
                                  ? null
                                  : _requestVerificationCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _codeSent
                                    ? const Color(0xFFE8EEF2)
                                    : const Color(0xFF006FFF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                              ),
                              child: _isRequestingCode
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _codeSent ? '발송완료' : '받기',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: _codeSent
                                            ? const Color(0xFF757B80)
                                            : Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),

                      // 인증번호 입력 (코드 발송 후에만 표시)
                      if (_codeSent) ...[
                        const SizedBox(height: 24),
                        _buildLabel('인증번호'),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: _verificationCodeController,
                                hintText: '인증번호 6자리를 입력하세요',
                                keyboardType: TextInputType.number,
                                errorText: _verificationCodeError,
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _isVerifyingCode ? null : _verifyCode,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF006FFF),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                ),
                                child: _isVerifyingCode
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
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
                                          fontSize: 14,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
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
                '비밀번호 찾기',
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: enabled ? const Color(0xFFF2F8FC) : const Color(0xFFE8EEF2),
            borderRadius: BorderRadius.circular(12),
            border: errorText != null
                ? Border.all(color: Colors.red, width: 1)
                : null,
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            enabled: enabled,
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: enabled ? const Color(0xFF17191A) : const Color(0xFF757B80),
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

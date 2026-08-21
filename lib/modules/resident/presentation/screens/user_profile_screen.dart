import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:building_manage_front/modules/auth/presentation/providers/auth_state_provider.dart';
import 'package:building_manage_front/modules/resident/presentation/widgets/consent_detail_sheet.dart';
import 'package:building_manage_front/shared/constants/legal_documents.dart';
import 'package:building_manage_front/shared/widgets/custom_confirmation_dialog.dart';
import 'package:building_manage_front/shared/widgets/error_alert.dart';
import 'package:building_manage_front/data/datasources/auth_remote_datasource.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isWithdrawing = false;

  String _formatPhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return '-';

    final digits = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.isEmpty) return phoneNumber;

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    } else if (digits.length == 10) {
      return '${digits.substring(0, 2)}-${digits.substring(2, 6)}-${digits.substring(6)}';
    }

    return phoneNumber;
  }

  /// 회원 탈퇴 확인 다이얼로그 표시
  Future<void> _showWithdrawConfirmDialog() async {
    final confirmed = await showCustomConfirmationDialog(
      context: context,
      title: '회원 탈퇴',
      content: const Text(
        '정말 탈퇴하시겠습니까?\n탈퇴 시 모든 정보가 삭제되며\n복구할 수 없습니다.',
        textAlign: TextAlign.center,
      ),
      confirmText: '탈퇴하기',
      cancelText: '취소',
      isDestructive: true,
      barrierDismissible: false,
      confirmOnLeft: false,  // 탈퇴하기 버튼을 오른쪽에 배치
    );

    if (confirmed == true && mounted) {
      _showPasswordInputDialog();
    }
  }

  /// 비밀번호 입력 다이얼로그 표시
  Future<void> _showPasswordInputDialog() async {
    final passwordController = TextEditingController();
    bool obscurePassword = true;
    String? errorMessage;

    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(32, 48, 32, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '비밀번호 확인',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF17191A),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '본인 확인을 위해\n비밀번호를 입력해주세요.',
                  style: TextStyle(
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: Color(0xFF17191A),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    hintText: '비밀번호',
                    hintStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Color(0xFF757B80),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF2F8FC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF757B80),
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscurePassword = !obscurePassword;
                        });
                      },
                    ),
                    errorText: errorMessage,
                    errorStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 12,
                      color: Color(0xFFFF3B30),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(context).pop(null),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF006FFF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          '취소',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final password = passwordController.text.trim();
                          if (password.isEmpty) {
                            setDialogState(() {
                              errorMessage = '비밀번호를 입력해주세요.';
                            });
                            return;
                          }
                          Navigator.of(context).pop(password);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFEFF6FF),
                          foregroundColor: const Color(0xFF006FFF),
                          minimumSize: const Size.fromHeight(64),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          elevation: 0,
                        ),
                        child: const Text(
                          '확인',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (password != null && password.isNotEmpty && mounted) {
      await _executeWithdraw(password);
    }
  }

  /// 회원 탈퇴 실행
  Future<void> _executeWithdraw(String password) async {
    setState(() {
      _isWithdrawing = true;
    });

    // 로딩 오버레이를 먼저 내린 뒤 실패 안내를 띄우기 위해 예외를 보관한다.
    Object? failure;

    try {
      final authDataSource = ref.read(authRemoteDataSourceProvider);
      await authDataSource.withdrawUser(password: password);

      // 탈퇴 성공 - 로그아웃 처리
      if (mounted) {
        final authStateNotifier = ref.read(authStateProvider.notifier);
        await authStateNotifier.logout();

        // 홈으로 이동
        if (mounted) {
          context.go('/');
        }
      }
    } catch (e) {
      failure = e;
    } finally {
      if (mounted) {
        setState(() {
          _isWithdrawing = false;
        });
      }
    }

    if (failure != null && mounted) {
      await showErrorAlert(
        context,
        title: '회원 탈퇴 실패',
        error: failure,
        fallback: '회원 탈퇴 중 오류가 발생했습니다. 잠시 후 다시 시도해 주세요.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // 상단 네비게이션 바
                _buildTopBar(context),

                // 내 정보 컨텐츠
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 8),

                          // 프로필 아이콘
                          Center(
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F8FC),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Color(0xFF006FFF),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 정보 항목들
                          _buildInfoItem('이름', currentUser?.name ?? '-'),
                          _buildDivider(),
                          _buildInfoItem('휴대폰 번호', _formatPhoneNumber(currentUser?.phoneNumber)),
                          _buildDivider(),
                          _buildInfoItem('건물명', currentUser?.buildingName ?? '-'),
                          _buildDivider(),
                          _buildActionItem(
                            context,
                            '비밀번호 수정',
                            () => context.pushNamed('changePassword'),
                          ),

                          const SizedBox(height: 32),

                          // 약관 및 정책 섹션
                          const Text(
                            '약관 및 정책',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDivider(),
                          _buildActionItem(
                            context,
                            '서비스 이용약관',
                            () => ConsentDetailSheet.show(
                              context,
                              title: '서비스 이용약관',
                              content: LegalDocuments.termsOfService,
                            ),
                          ),
                          _buildDivider(),
                          _buildActionItem(
                            context,
                            '개인정보 처리방침',
                            () => ConsentDetailSheet.show(
                              context,
                              title: '개인정보 처리방침',
                              content: LegalDocuments.privacyPolicy,
                            ),
                          ),

                          const SizedBox(height: 32),

                          // 계정 관리 섹션
                          const Text(
                            '계정 관리',
                            style: TextStyle(
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildDivider(),
                          _buildWithdrawItem(
                            context,
                            '회원 탈퇴',
                            _showWithdrawConfirmDialog,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 로딩 오버레이
            if (_isWithdrawing)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
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
                '내 정보',
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

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              color: Color(0xFF757B80),
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF17191A),
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: const Color(0xFFE8EEF2),
    );
  }

  Widget _buildActionItem(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFF757B80),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF757B80),
            ),
          ],
        ),
      ),
    );
  }

  /// 회원 탈퇴 메뉴 아이템 (빨간색)
  Widget _buildWithdrawItem(BuildContext context, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: Color(0xFFFF3B30),  // 빨간색으로 강조
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFFFF3B30),
            ),
          ],
        ),
      ),
    );
  }
}

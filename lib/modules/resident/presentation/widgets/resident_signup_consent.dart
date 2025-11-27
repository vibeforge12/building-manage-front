import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:building_manage_front/modules/resident/data/models/consent_agreement.dart';
import 'package:building_manage_front/modules/resident/presentation/providers/signup_form_provider.dart';
import 'package:building_manage_front/modules/resident/presentation/widgets/consent_checkbox_item.dart';
import 'package:building_manage_front/modules/resident/presentation/widgets/consent_detail_sheet.dart';
import 'package:building_manage_front/shared/constants/legal_documents.dart';

/// 회원가입 Step 1: 약관 동의 페이지
class ResidentSignupConsent extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ResidentSignupConsent({
    super.key,
    required this.onNext,
  });

  @override
  ConsumerState<ResidentSignupConsent> createState() =>
      _ResidentSignupConsentState();
}

class _ResidentSignupConsentState extends ConsumerState<ResidentSignupConsent> {
  bool _agreeAll = false;
  bool _agreeTerms = false; // 서비스 이용약관 (필수)
  bool _agreePrivacy = false; // 개인정보 처리방침 (필수)
  bool _agreeAge = false; // 만 14세 이상 (필수)
  bool _agreeMarketing = false; // 마케팅 정보 수신 (선택)

  bool get _isRequiredAgreed => _agreeTerms && _agreePrivacy && _agreeAge;

  void _onAllAgreeChanged(bool value) {
    setState(() {
      _agreeAll = value;
      _agreeTerms = value;
      _agreePrivacy = value;
      _agreeAge = value;
      _agreeMarketing = value;
    });
  }

  void _updateAllAgreeState() {
    setState(() {
      _agreeAll =
          _agreeTerms && _agreePrivacy && _agreeAge && _agreeMarketing;
    });
  }

  void _onNext() {
    if (!_isRequiredAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('필수 약관에 동의해 주세요.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Provider에 동의 정보 저장
    ref.read(signupFormProvider.notifier).setConsentAgreement(
          ConsentAgreement(
            termsOfService: _agreeTerms,
            privacyPolicy: _agreePrivacy,
            ageVerification: _agreeAge,
            marketingConsent: _agreeMarketing,
            agreedAt: DateTime.now(),
          ),
        );

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // 상단 X 버튼 영역
            Padding(
              padding: const EdgeInsets.only(top: 8, right: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    onPressed: () {
                      // 폼 상태 초기화 후 홈으로 이동
                      ref.read(signupFormProvider.notifier).reset();
                      context.go('/');
                    },
                    icon: const Icon(
                      Icons.close,
                      color: Color(0xFF464A4D),
                      size: 24,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목
                    const Text(
                      '서비스 이용을 위해\n약관에 동의해 주세요',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17191A),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '원활한 서비스 이용을 위해 약관 동의가 필요합니다.',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF757B80),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // 전체 동의
                    ConsentCheckboxItem(
                      title: '전체 동의하기',
                      isChecked: _agreeAll,
                      isRequired: false,
                      isAllAgree: true,
                      onChanged: _onAllAgreeChanged,
                    ),
                    const SizedBox(height: 16),

                    // 구분선
                    const Divider(height: 1, color: Color(0xFFE8EEF2)),
                    const SizedBox(height: 8),

                    // 서비스 이용약관 (필수)
                    ConsentCheckboxItem(
                      title: '서비스 이용약관',
                      isChecked: _agreeTerms,
                      isRequired: true,
                      onChanged: (value) {
                        setState(() => _agreeTerms = value);
                        _updateAllAgreeState();
                      },
                      onDetailTap: () => _showTermsDetail(),
                    ),

                    // 개인정보 처리방침 (필수)
                    ConsentCheckboxItem(
                      title: '개인정보 처리방침',
                      isChecked: _agreePrivacy,
                      isRequired: true,
                      onChanged: (value) {
                        setState(() => _agreePrivacy = value);
                        _updateAllAgreeState();
                      },
                      onDetailTap: () => _showPrivacyDetail(),
                    ),

                    // 만 14세 이상 (필수)
                    ConsentCheckboxItem(
                      title: '만 14세 이상입니다',
                      isChecked: _agreeAge,
                      isRequired: true,
                      onChanged: (value) {
                        setState(() => _agreeAge = value);
                        _updateAllAgreeState();
                      },
                    ),

                    // 마케팅 정보 수신 (선택)
                    ConsentCheckboxItem(
                      title: '마케팅 정보 수신 동의',
                      isChecked: _agreeMarketing,
                      isRequired: false,
                      onChanged: (value) {
                        setState(() => _agreeMarketing = value);
                        _updateAllAgreeState();
                      },
                      onDetailTap: () => _showMarketingDetail(),
                    ),
                  ],
                ),
              ),
            ),

            // 하단 버튼 영역
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFF2F4F6), width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _isRequiredAgreed ? _onNext : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isRequiredAgreed
                          ? const Color(0xFF006FFF)
                          : const Color(0xFFE8EEF2),
                      disabledBackgroundColor: const Color(0xFFE8EEF2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      '다음',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _isRequiredAgreed
                            ? Colors.white
                            : const Color(0xFF757B80),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsDetail() {
    ConsentDetailSheet.show(
      context,
      title: '서비스 이용약관',
      content: LegalDocuments.termsOfService,
    );
  }

  void _showPrivacyDetail() {
    ConsentDetailSheet.show(
      context,
      title: '개인정보 처리방침',
      content: LegalDocuments.privacyPolicy,
    );
  }

  void _showMarketingDetail() {
    ConsentDetailSheet.show(
      context,
      title: '마케팅 정보 수신 동의',
      content: LegalDocuments.marketingConsent,
    );
  }
}

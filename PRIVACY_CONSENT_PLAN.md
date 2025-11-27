# 개인정보 이용 동의 구현 계획서

## 1. 개요

### 1.1 목적
Apple App Store 및 Google Play Store 심사 통과를 위한 개인정보 처리방침 동의 기능 구현

### 1.2 배경
- **Apple**: App Store Review Guidelines 5.1.1 - 개인정보 수집 시 명확한 동의 필요
- **Google**: Play Console 정책 - 개인정보 처리방침 필수, 민감 정보 수집 동의 필요
- **한국 법률**: 개인정보보호법 - 개인정보 수집·이용 동의 의무화

### 1.3 현재 회원가입 플로우 분석
```
Step 1: 동/호수, 아이디, 비밀번호 입력
   ↓
Step 2: 건물 선택
   ↓
Step 3: 이름, 휴대폰 번호 입력
   ↓
회원가입 완료
```

**수집되는 개인정보:**
| 항목 | 수집 위치 | 필수 여부 |
|------|----------|----------|
| 아이디 | Step 1 | 필수 |
| 비밀번호 | Step 1 | 필수 |
| 동/호수 | Step 1 | 필수 |
| 건물 정보 | Step 2 | 필수 |
| 이름 | Step 3 | 필수 |
| 휴대폰 번호 | Step 3 | 필수 |

---

## 2. 구현 계획

### 2.1 필수 동의 항목

#### 2.1.1 개인정보 처리방침 동의 (필수)
- **내용**: 개인정보 수집 항목, 수집 목적, 보유 기간, 제3자 제공 여부
- **법적 근거**: 개인정보보호법 제15조

#### 2.1.2 서비스 이용약관 동의 (필수)
- **내용**: 서비스 이용 조건, 회원 의무, 서비스 제공자 책임
- **법적 근거**: 전자상거래법, 정보통신망법

#### 2.1.3 만 14세 이상 확인 (필수)
- **내용**: 만 14세 미만 아동의 경우 법정대리인 동의 필요
- **법적 근거**: 개인정보보호법 제22조

### 2.2 선택 동의 항목

#### 2.2.1 마케팅 정보 수신 동의 (선택)
- **내용**: 이벤트, 프로모션 등 마케팅 정보 수신
- SMS/푸시 알림 동의 포함

#### 2.2.2 위치정보 이용 동의 (선택, 향후 확장 시)
- **내용**: 위치 기반 서비스 제공 시 필요

---

## 3. UI/UX 설계

### 3.1 동의 화면 위치
**권장 방안: 약관 동의를 별도 Step 1 페이지로 분리하여 총 4단계로 구성**

> ⚠️ **법적 요구사항**: 개인정보보호법 제15조에 따라 개인정보 수집 **전에** 동의를 받아야 합니다.

```
Step 1 (신규): 약관 동의 페이지  ← 별도 페이지로 신규 생성
   ↓
Step 2: 동/호수, 아이디, 비밀번호 입력 (기존 Step 1)
   ↓
Step 3: 건물 선택 (기존 Step 2)
   ↓
Step 4: 이름, 휴대폰 번호 입력 (기존 Step 3)
   ↓
회원가입 완료
```

**장점:**
- 약관 동의에 집중할 수 있는 별도 화면 제공
- 법적 요구사항 명확히 충족 (개인정보 입력 전 동의)
- 기존 Step 1~3 로직 변경 최소화 (번호만 +1)
- 앱 스토어 심사 시 약관 동의 플로우 명확히 보여줌

### 3.2 Step 1 약관 동의 화면 (신규 페이지)

```
┌─────────────────────────────────┐
│      < 회원가입 (1/4)            │
├─────────────────────────────────┤
│                                 │
│  서비스 이용을 위해              │
│  약관에 동의해 주세요            │
│                                 │
│  ┌─────────────────────────┐   │
│  │ ☑ 전체 동의하기          │   │
│  └─────────────────────────┘   │
│                                 │
│  ────────────────────────────   │
│                                 │
│  ☑ [필수] 서비스 이용약관     >  │
│                                 │
│  ☑ [필수] 개인정보 처리방침   >  │
│                                 │
│  ☑ [필수] 만 14세 이상입니다    │
│                                 │
│  ☐ [선택] 마케팅 정보 수신 동의 >│
│                                 │
│                                 │
│                                 │
│                                 │
│  ┌─────────────────────────┐   │
│  │          다음            │   │  ← 필수 항목 모두 동의 시 활성화
│  └─────────────────────────┘   │
│                                 │
└─────────────────────────────────┘
```

**필수 약관 미동의 시:**
- "다음" 버튼 비활성화 (회색 처리)
- 버튼 클릭 시 "필수 약관에 동의해 주세요" 메시지 표시

### 3.3 상세 약관 보기
- 각 약관 항목 터치 시 전체 내용 표시 (별도 화면 또는 바텀시트)
- 스크롤 가능한 텍스트 뷰로 전체 내용 확인 가능

### 3.4 UX 규칙
1. **전체 동의** 체크 시 모든 항목 자동 체크
2. **필수 항목** 미체크 시 회원가입 버튼 비활성화
3. **필수 항목** 미체크 상태에서 버튼 클릭 시 안내 메시지 표시
4. 각 약관 내용은 **반드시 열람 가능**해야 함 (앱 스토어 요구사항)

---

## 4. 구현 상세

### 4.1 파일 구조

```
lib/
├── modules/
│   └── resident/
│       ├── presentation/
│       │   ├── screens/
│       │   │   └── resident_signup_screen.dart          (수정 - 4단계로 변경)
│       │   └── widgets/
│       │       ├── resident_signup_consent.dart         (신규 - Step 1 약관 동의 위젯)
│       │       ├── resident_signup_step1.dart           (기존 유지 - Step 2로 이동)
│       │       ├── resident_signup_step2.dart           (기존 유지 - Step 3로 이동)
│       │       ├── resident_signup_step3.dart           (기존 유지 - Step 4로 이동)
│       │       ├── consent_checkbox_item.dart           (신규 - 체크박스 위젯)
│       │       └── consent_detail_sheet.dart            (신규 - 약관 상세 바텀시트)
│       └── data/
│           └── models/
│               └── consent_agreement.dart               (신규 - 동의 데이터 모델)
├── shared/
│   └── constants/
│       └── legal_documents.dart                         (신규 - 약관 텍스트 상수)
└── assets/
    └── legal/
        ├── terms_of_service.md                          (신규 - 서비스 이용약관)
        └── privacy_policy.md                            (신규 - 개인정보 처리방침)
```

### 4.2 데이터 모델

```dart
// lib/modules/resident/data/models/consent_agreement.dart

class ConsentAgreement {
  final bool termsOfService;        // 서비스 이용약관 (필수)
  final bool privacyPolicy;         // 개인정보 처리방침 (필수)
  final bool ageVerification;       // 만 14세 이상 확인 (필수)
  final bool marketingConsent;      // 마케팅 정보 수신 (선택)
  final DateTime agreedAt;          // 동의 일시

  bool get isRequiredComplete =>
      termsOfService && privacyPolicy && ageVerification;
}
```

### 4.3 Provider 확장

```dart
// lib/modules/resident/presentation/providers/signup_form_provider.dart 확장

class SignupFormState {
  // 기존 필드...
  final ConsentAgreement? consentAgreement;  // 추가
}
```

### 4.4 API 확장

회원가입 요청 시 동의 정보 포함:

```dart
// POST /api/v1/auth/resident/register

{
  "username": "user123",
  "password": "password123",
  "name": "홍길동",
  "phoneNumber": "01012345678",
  "dong": "101",
  "hosu": "1001",
  "buildingId": "building-uuid",
  // 신규 추가
  "agreements": {
    "termsOfService": true,
    "privacyPolicy": true,
    "ageVerification": true,
    "marketingConsent": false,
    "agreedAt": "2025-01-15T10:30:00Z"
  }
}
```

### 4.5 신규 Step 1 약관 동의 위젯

**신규 `resident_signup_consent.dart` 생성 (Step 1 - 약관 동의 전용 페이지)**

```dart
// lib/modules/resident/presentation/widgets/resident_signup_consent.dart

class ResidentSignupConsent extends ConsumerStatefulWidget {
  final VoidCallback onNext;

  const ResidentSignupConsent({super.key, required this.onNext});

  @override
  ConsumerState<ResidentSignupConsent> createState() => _ResidentSignupConsentState();
}

class _ResidentSignupConsentState extends ConsumerState<ResidentSignupConsent> {
  bool _agreeAll = false;
  bool _agreeTerms = false;        // 서비스 이용약관 (필수)
  bool _agreePrivacy = false;      // 개인정보 처리방침 (필수)
  bool _agreeAge = false;          // 만 14세 이상 (필수)
  bool _agreeMarketing = false;    // 마케팅 정보 수신 (선택)

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
      _agreeAll = _agreeTerms && _agreePrivacy && _agreeAge && _agreeMarketing;
    });
  }

  void _onNext() {
    if (!_isRequiredAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('필수 약관에 동의해 주세요.')),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '서비스 이용을 위해\n약관에 동의해 주세요',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17191A),
            ),
          ),
          const SizedBox(height: 24),

          // 전체 동의
          ConsentCheckboxItem(
            title: '전체 동의하기',
            isChecked: _agreeAll,
            isRequired: false,
            isAllAgree: true,
            onChanged: _onAllAgreeChanged,
          ),

          const Divider(height: 1, color: Color(0xFFE8EEF2)),

          // 서비스 이용약관
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

          // 개인정보 처리방침
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

          // 만 14세 이상
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

          const SizedBox(height: 40),

          // 다음 버튼
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: _isRequiredAgreed ? _onNext : null,
              style: FilledButton.styleFrom(
                backgroundColor: _isRequiredAgreed
                    ? const Color(0xFF006FFF)
                    : const Color(0xFFE8EEF2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                '다음',
                style: TextStyle(
                  color: _isRequiredAgreed ? Colors.white : const Color(0xFF757B80),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
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
```

### 4.6 ResidentSignupScreen 수정 (3단계 → 4단계)

```dart
// lib/modules/resident/presentation/screens/resident_signup_screen.dart 수정

class _ResidentSignupScreenState extends ConsumerState<ResidentSignupScreen> {
  int _currentStep = 0;  // 0: 약관동의, 1: 기본정보, 2: 건물선택, 3: 개인정보

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('회원가입 (${_currentStep + 1}/4)'),  // 4단계로 변경
        // ...
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          // Step 1: 약관 동의 (신규)
          ResidentSignupConsent(
            onNext: () => setState(() => _currentStep = 1),
          ),
          // Step 2: 동/호수, 아이디, 비밀번호 (기존 Step 1)
          ResidentSignupStep1(
            onNext: () => setState(() => _currentStep = 2),
            onPrev: () => setState(() => _currentStep = 0),
          ),
          // Step 3: 건물 선택 (기존 Step 2)
          ResidentSignupStep2(
            onNext: () => setState(() => _currentStep = 3),
            onPrev: () => setState(() => _currentStep = 1),
          ),
          // Step 4: 이름, 휴대폰 번호 (기존 Step 3)
          ResidentSignupStep3(
            onPrev: () => setState(() => _currentStep = 2),
          ),
        ],
      ),
    );
  }
}
```

### 4.7 ConsentCheckboxItem 위젯

```dart
// lib/modules/resident/presentation/widgets/consent_checkbox_item.dart

class ConsentCheckboxItem extends StatelessWidget {
  final String title;
  final bool isChecked;
  final bool isRequired;
  final bool isAllAgree;
  final ValueChanged<bool> onChanged;
  final VoidCallback? onDetailTap;

  const ConsentCheckboxItem({
    super.key,
    required this.title,
    required this.isChecked,
    required this.isRequired,
    this.isAllAgree = false,
    required this.onChanged,
    this.onDetailTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!isChecked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            // 체크박스 아이콘
            Icon(
              isChecked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isChecked ? const Color(0xFF006FFF) : const Color(0xFFBDC5CB),
              size: 24,
            ),
            const SizedBox(width: 12),

            // 제목 ([필수] 또는 [선택] 포함)
            Expanded(
              child: Text(
                isAllAgree ? title : '${isRequired ? "[필수]" : "[선택]"} $title',
                style: TextStyle(
                  fontSize: isAllAgree ? 16 : 14,
                  fontWeight: isAllAgree ? FontWeight.w700 : FontWeight.w400,
                  color: const Color(0xFF17191A),
                ),
              ),
            ),

            // 상세 보기 화살표 (onDetailTap이 있을 때만)
            if (onDetailTap != null)
              IconButton(
                icon: const Icon(Icons.chevron_right, color: Color(0xFFBDC5CB)),
                onPressed: onDetailTap,
              ),
          ],
        ),
      ),
    );
  }
}
```

### 4.8 약관 상세 바텀시트

```dart
// lib/modules/resident/presentation/widgets/consent_detail_sheet.dart

class ConsentDetailSheet extends StatelessWidget {
  final String title;
  final String content;

  const ConsentDetailSheet({
    super.key,
    required this.title,
    required this.content,
  });

  static void show(BuildContext context, {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ConsentDetailSheet(title: title, content: content),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFE8EEF2))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // 약관 내용
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.6,
                    color: Color(0xFF464A4D),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
```

---

## 5. 법적 문서 작성

### 5.1 개인정보 처리방침 필수 포함 항목

1. **개인정보 수집 항목**
   - 필수: 아이디, 비밀번호, 이름, 휴대폰 번호, 동/호수, 건물 정보
   - 자동 수집: 기기 정보, 앱 사용 기록, IP 주소

2. **수집 및 이용 목적**
   - 회원 가입 및 관리
   - 건물 관리 서비스 제공
   - 민원 처리 및 공지사항 전달
   - 서비스 개선 및 통계 분석

3. **보유 및 이용 기간**
   - 회원 탈퇴 시까지 또는 법령에 따른 보존 기간
   - 관련 법령: 전자상거래법 (5년), 통신비밀보호법 (3개월) 등

4. **개인정보의 제3자 제공**
   - 건물 관리자에게 민원 처리 목적으로 제공
   - 법적 요구 시 관계 기관에 제공

5. **개인정보 처리 위탁**
   - 클라우드 서비스 제공자 (AWS 등)
   - SMS 발송 대행사

6. **이용자의 권리**
   - 열람, 정정, 삭제, 처리정지 요청권
   - 동의 철회권

7. **개인정보 보호책임자**
   - 이름, 연락처, 이메일

### 5.2 서비스 이용약관 필수 포함 항목

1. 서비스 목적 및 정의
2. 회원 가입 및 탈퇴
3. 서비스 이용 규칙
4. 금지 행위
5. 서비스 제공자의 의무
6. 면책 조항
7. 분쟁 해결

---

## 6. 앱 스토어 대응

### 6.1 Apple App Store

#### App Store Connect 설정
1. **App Privacy** 섹션 작성 필수
   - 수집하는 데이터 유형 명시
   - 데이터 사용 목적 명시
   - 사용자 추적 여부 명시

2. **Privacy Policy URL** 필수 등록
   - 웹에서 접근 가능한 개인정보 처리방침 URL

#### 심사 대응
- 앱 내에서 약관 전체 내용 열람 가능해야 함
- 동의 체크박스 명확하게 표시
- 강제 동의 금지 (선택 항목은 선택으로 명시)

### 6.2 Google Play Store

#### Play Console 설정
1. **개인정보처리방침** URL 등록 (필수)
2. **데이터 보안** 섹션 작성
   - 수집 데이터 유형
   - 데이터 공유 여부
   - 데이터 보안 방식

#### 심사 대응
- 민감 권한 사용 시 명확한 설명 필요
- 데이터 삭제 요청 처리 방법 안내

### 6.3 웹 호스팅 필요 문서

앱 스토어 등록 시 웹 URL이 필요한 문서:
1. **개인정보 처리방침** - `https://your-domain.com/privacy`
2. **서비스 이용약관** - `https://your-domain.com/terms`
3. **고객 지원 페이지** - `https://your-domain.com/support`

---

## 7. 구현 일정

### Phase 1: 기반 작업 (1일)
- [ ] 개인정보 처리방침 문서 작성 (`assets/legal/privacy_policy.md`)
- [ ] 서비스 이용약관 문서 작성 (`assets/legal/terms_of_service.md`)
- [ ] ConsentAgreement 데이터 모델 생성
- [ ] legal_documents.dart 약관 텍스트 상수 작성

### Phase 2: UI 구현 (1일)
- [ ] ConsentCheckboxItem 위젯 구현
- [ ] ConsentDetailSheet 바텀시트 구현
- [ ] **resident_signup_consent.dart 신규 생성 (Step 1 약관 동의 페이지)**
- [ ] 전체 동의/개별 동의 로직 구현

### Phase 3: 기존 화면 통합 (0.5일)
- [ ] **resident_signup_screen.dart 수정 (3단계 → 4단계)**
- [ ] SignupFormProvider에 동의 정보 필드 추가
- [ ] API 요청 데이터에 동의 정보 포함
- [ ] 회원가입 완료 시 동의 일시 기록

### Phase 4: 테스트 및 배포 준비 (0.5일)
- [ ] 4단계 회원가입 플로우 테스트
- [ ] 앱 스토어 메타데이터 준비 (Privacy Policy URL)
- [ ] 웹 호스팅 문서 배포 (필요 시)

---

## 8. 체크리스트

### 구현 전 확인
- [ ] 법무팀/담당자와 약관 내용 검토
- [ ] 개인정보 보호책임자 지정
- [ ] 웹 호스팅 URL 확보

### 구현 중 확인
- [ ] 모든 필수 동의 항목 구현
- [ ] 약관 전문 열람 기능 구현
- [ ] 동의 일시 기록 기능 구현
- [ ] 선택/필수 구분 명확히 표시

### 배포 전 확인
- [ ] Apple App Store Privacy 섹션 작성
- [ ] Google Play 데이터 보안 섹션 작성
- [ ] Privacy Policy URL 등록
- [ ] Terms of Service URL 등록

---

## 9. 참고 자료

### 관련 법령
- [개인정보보호법](https://www.law.go.kr/법령/개인정보보호법)
- [정보통신망법](https://www.law.go.kr/법령/정보통신망이용촉진및정보보호등에관한법률)
- [전자상거래법](https://www.law.go.kr/법령/전자상거래등에서의소비자보호에관한법률)

### 앱 스토어 가이드라인
- [Apple App Store Review Guidelines - 5.1 Privacy](https://developer.apple.com/app-store/review/guidelines/#privacy)
- [Google Play Policy - User Data](https://support.google.com/googleplay/android-developer/answer/10144311)

### 개인정보보호위원회 자료
- [개인정보 처리방침 작성 가이드라인](https://www.pipc.go.kr/)

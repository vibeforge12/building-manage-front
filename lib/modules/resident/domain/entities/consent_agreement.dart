import 'package:building_manage_front/shared/constants/legal_documents.dart';

/// 약관 동의 정보를 담는 값 객체
///
/// 회원가입 요청의 `agreements` 필드로 직렬화되어 서버에 저장된다.
class ConsentAgreement {
  /// 서비스 이용약관 동의 (필수)
  final bool termsOfService;

  /// 개인정보 처리방침 동의 (필수)
  final bool privacyPolicy;

  /// 만 14세 이상 확인 (필수)
  final bool ageVerification;

  /// 마케팅 정보 수신 동의 (선택)
  final bool marketingConsent;

  /// 동의 일시
  final DateTime agreedAt;

  /// 동의한 서비스 이용약관 문서의 버전
  ///
  /// 기본값은 앱에 내장된 전문의 버전([LegalDocuments.termsOfServiceVersion])이다.
  final String termsOfServiceVersion;

  /// 동의한 개인정보 처리방침 문서의 버전
  ///
  /// 기본값은 앱에 내장된 전문의 버전([LegalDocuments.privacyPolicyVersion])이다.
  final String privacyPolicyVersion;

  /// 동의(또는 미동의)한 마케팅 정보 수신 동의 문서의 버전
  ///
  /// 기본값은 앱에 내장된 전문의 버전([LegalDocuments.marketingConsentVersion])이다.
  final String marketingConsentVersion;

  // 만 14세 이상 확인([ageVerification])은 문서가 아니라 사실 확인이므로
  // 대응하는 버전이 없다.

  const ConsentAgreement({
    required this.termsOfService,
    required this.privacyPolicy,
    required this.ageVerification,
    required this.marketingConsent,
    required this.agreedAt,
    this.termsOfServiceVersion = LegalDocuments.termsOfServiceVersion,
    this.privacyPolicyVersion = LegalDocuments.privacyPolicyVersion,
    this.marketingConsentVersion = LegalDocuments.marketingConsentVersion,
  });

  /// 필수 약관 모두 동의했는지 확인
  bool get isRequiredComplete =>
      termsOfService && privacyPolicy && ageVerification;

  /// 모든 약관 동의했는지 확인
  bool get isAllComplete =>
      termsOfService && privacyPolicy && ageVerification && marketingConsent;

  /// API 요청용 JSON 변환
  ///
  /// [agreedAt]은 타임존 오프셋을 명시한 ISO 8601 문자열로 직렬화한다.
  /// (예: `2026-08-21T15:30:00+09:00`)
  ///
  /// 약관 버전은 문서별로 개정되므로 문서마다 따로 전송한다.
  Map<String, dynamic> toJson() {
    return {
      'termsOfService': termsOfService,
      'privacyPolicy': privacyPolicy,
      'ageVerification': ageVerification,
      'marketingConsent': marketingConsent,
      'agreedAt': _formatIso8601WithOffset(agreedAt),
      'termsOfServiceVersion': termsOfServiceVersion,
      'privacyPolicyVersion': privacyPolicyVersion,
      'marketingConsentVersion': marketingConsentVersion,
    };
  }

  /// JSON에서 객체 생성
  factory ConsentAgreement.fromJson(Map<String, dynamic> json) {
    final agreedAtRaw = json['agreedAt'] as String?;
    return ConsentAgreement(
      termsOfService: json['termsOfService'] as bool? ?? false,
      privacyPolicy: json['privacyPolicy'] as bool? ?? false,
      ageVerification: json['ageVerification'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      // 서버가 UTC(Z)로 내려주는 경우가 있어 항상 로컬 시각으로 변환한다.
      agreedAt: agreedAtRaw != null
          ? DateTime.parse(agreedAtRaw).toLocal()
          : DateTime.now(),
      termsOfServiceVersion: json['termsOfServiceVersion'] as String? ??
          LegalDocuments.termsOfServiceVersion,
      privacyPolicyVersion: json['privacyPolicyVersion'] as String? ??
          LegalDocuments.privacyPolicyVersion,
      marketingConsentVersion: json['marketingConsentVersion'] as String? ??
          LegalDocuments.marketingConsentVersion,
    );
  }

  /// 복사본 생성
  ConsentAgreement copyWith({
    bool? termsOfService,
    bool? privacyPolicy,
    bool? ageVerification,
    bool? marketingConsent,
    DateTime? agreedAt,
    String? termsOfServiceVersion,
    String? privacyPolicyVersion,
    String? marketingConsentVersion,
  }) {
    return ConsentAgreement(
      termsOfService: termsOfService ?? this.termsOfService,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      ageVerification: ageVerification ?? this.ageVerification,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      agreedAt: agreedAt ?? this.agreedAt,
      termsOfServiceVersion:
          termsOfServiceVersion ?? this.termsOfServiceVersion,
      privacyPolicyVersion: privacyPolicyVersion ?? this.privacyPolicyVersion,
      marketingConsentVersion:
          marketingConsentVersion ?? this.marketingConsentVersion,
    );
  }

  /// 기본값 (모두 미동의)
  factory ConsentAgreement.initial() {
    return ConsentAgreement(
      termsOfService: false,
      privacyPolicy: false,
      ageVerification: false,
      marketingConsent: false,
      agreedAt: DateTime.now(),
    );
  }
}

/// 로컬 시각 + 타임존 오프셋을 명시한 ISO 8601 문자열로 변환한다.
///
/// `DateTime.toIso8601String()`은 로컬 DateTime을 오프셋 없이 출력해
/// 서버가 UTC로 오해할 수 있으므로, 오프셋을 직접 붙여 모호함을 없앤다.
String _formatIso8601WithOffset(DateTime dateTime) {
  final local = dateTime.toLocal();
  // 밀리초/마이크로초를 제거해 `yyyy-MM-ddTHH:mm:ss` 형태로 맞춘다.
  final timestamp = local.toIso8601String().split('.').first;

  final offset = local.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final absOffset = offset.abs();
  final hours = absOffset.inHours.toString().padLeft(2, '0');
  final minutes = (absOffset.inMinutes % 60).toString().padLeft(2, '0');

  return '$timestamp$sign$hours:$minutes';
}

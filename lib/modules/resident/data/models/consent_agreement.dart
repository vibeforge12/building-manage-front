/// 약관 동의 정보를 담는 데이터 모델
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

  const ConsentAgreement({
    required this.termsOfService,
    required this.privacyPolicy,
    required this.ageVerification,
    required this.marketingConsent,
    required this.agreedAt,
  });

  /// 필수 약관 모두 동의했는지 확인
  bool get isRequiredComplete =>
      termsOfService && privacyPolicy && ageVerification;

  /// 모든 약관 동의했는지 확인
  bool get isAllComplete =>
      termsOfService && privacyPolicy && ageVerification && marketingConsent;

  /// API 요청용 JSON 변환
  Map<String, dynamic> toJson() {
    return {
      'termsOfService': termsOfService,
      'privacyPolicy': privacyPolicy,
      'ageVerification': ageVerification,
      'marketingConsent': marketingConsent,
      'agreedAt': agreedAt.toIso8601String(),
    };
  }

  /// JSON에서 객체 생성
  factory ConsentAgreement.fromJson(Map<String, dynamic> json) {
    return ConsentAgreement(
      termsOfService: json['termsOfService'] as bool? ?? false,
      privacyPolicy: json['privacyPolicy'] as bool? ?? false,
      ageVerification: json['ageVerification'] as bool? ?? false,
      marketingConsent: json['marketingConsent'] as bool? ?? false,
      agreedAt: json['agreedAt'] != null
          ? DateTime.parse(json['agreedAt'] as String)
          : DateTime.now(),
    );
  }

  /// 복사본 생성
  ConsentAgreement copyWith({
    bool? termsOfService,
    bool? privacyPolicy,
    bool? ageVerification,
    bool? marketingConsent,
    DateTime? agreedAt,
  }) {
    return ConsentAgreement(
      termsOfService: termsOfService ?? this.termsOfService,
      privacyPolicy: privacyPolicy ?? this.privacyPolicy,
      ageVerification: ageVerification ?? this.ageVerification,
      marketingConsent: marketingConsent ?? this.marketingConsent,
      agreedAt: agreedAt ?? this.agreedAt,
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

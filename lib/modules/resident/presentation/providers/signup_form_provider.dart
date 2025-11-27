// providers/signup_form_provider.dart
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:building_manage_front/modules/resident/data/models/consent_agreement.dart';

class SignupFormState {
  final String? dong;
  final String? hosu;
  final String? password;
  final String? passwordConfirm;
  final String? username;
  final String? name;
  final String? phoneNumber;
  final String? buildingId;
  final int currentStep;
  final bool isLoading;

  /// 약관 동의 정보
  final ConsentAgreement? consentAgreement;

  const SignupFormState({
    this.dong,
    this.hosu,
    this.password,
    this.passwordConfirm,
    this.username,
    this.name,
    this.phoneNumber,
    this.buildingId,
    this.currentStep = 1,
    this.isLoading = false,
    this.consentAgreement,
  });

  SignupFormState copyWith({
    String? dong,
    String? hosu,
    String? password,
    String? passwordConfirm,
    String? username,
    String? name,
    String? phoneNumber,
    String? buildingId,
    int? currentStep,
    bool? isLoading,
    ConsentAgreement? consentAgreement,
  }) {
    return SignupFormState(
      dong: dong ?? this.dong,
      hosu: hosu ?? this.hosu,
      password: password ?? this.password,
      passwordConfirm: passwordConfirm ?? this.passwordConfirm,
      username: username ?? this.username,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      buildingId: buildingId ?? this.buildingId,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      consentAgreement: consentAgreement ?? this.consentAgreement,
    );
  }

  /// 약관 동의 완료 여부 (필수 항목 모두 동의)
  bool get isConsentComplete =>
      consentAgreement != null && consentAgreement!.isRequiredComplete;

  bool get isStep1Valid =>
      dong != null && dong!.isNotEmpty &&
          hosu != null && hosu!.isNotEmpty &&
          password != null && password!.isNotEmpty &&
          passwordConfirm != null && passwordConfirm!.isNotEmpty &&
          password == passwordConfirm &&
          username != null && username!.isNotEmpty; // ✅ username도 Step1에서 채움

  bool get isStep2Valid =>
      username != null && username!.isNotEmpty &&
          name != null && name!.isNotEmpty &&
          phoneNumber != null && phoneNumber!.isNotEmpty &&
          buildingId != null && buildingId!.isNotEmpty;

  bool get canProceedToStep2 => isStep1Valid;
  bool get canSubmit => isStep1Valid && isStep2Valid;

  Map<String, dynamic> toApiRequest() {
    return {
      'username': username,
      'password': password,
      'name': name,
      'phoneNumber': phoneNumber,
      'dong': dong,
      'hosu': hosu,
      'buildingId': buildingId,
      // 약관 동의 정보 추가
      if (consentAgreement != null) 'agreements': consentAgreement!.toJson(),
    };
  }
}

class SignupFormNotifier extends StateNotifier<SignupFormState> {
  SignupFormNotifier() : super(const SignupFormState());

  /// 약관 동의 정보 저장 (Step 1)
  void setConsentAgreement(ConsentAgreement agreement) {
    state = state.copyWith(consentAgreement: agreement);
  }

  // ✅ Step2에서 username까지 함께 저장 (기존 Step1 → Step2로 변경)
  void updateStep1Data({
    required String username,
    required String dong,
    required String hosu,
    required String password,
    required String passwordConfirm,
  }) {
    state = state.copyWith(
      username: username.trim(),
      dong: dong.trim(),
      hosu: hosu.trim(),
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  // ✅ Step3/4에서 나머지 정보만 저장 (username은 유지)
  void updateStep2Data({
    required String name,
    required String phoneNumber,
    required String buildingId,
  }) {
    state = state.copyWith(
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      buildingId: buildingId.trim(),
    );
  }

  void nextStep() {
    if (state.currentStep < 4) {  // 4단계로 변경
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    if (step >= 1 && step <= 4) {  // 4단계로 변경
      state = state.copyWith(currentStep: step);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void reset() {
    state = const SignupFormState();
  }

  /// ✅ 최종 회원가입 API 호출 (예시)
  Future<({bool ok, String? message})> submitSignup({
    required String baseUrl, // 예: https://api.example.com
  }) async {
    final body = state.toApiRequest();
    try {
      setLoading(true);
      final resp = await http.post(
        Uri.parse('$baseUrl/auth/signup'), // 엔드포인트는 실제에 맞게
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return (ok: true, message: null);
      }
      return (ok: false, message: resp.body);
    } catch (e) {
      return (ok: false, message: e.toString());
    } finally {
      setLoading(false);
    }
  }
}

final signupFormProvider =
StateNotifierProvider<SignupFormNotifier, SignupFormState>(
      (ref) => SignupFormNotifier(),
);

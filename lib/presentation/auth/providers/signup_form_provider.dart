import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    );
  }

  bool get isStep1Valid =>
      dong != null &&
      dong!.isNotEmpty &&
      hosu != null &&
      hosu!.isNotEmpty &&
      password != null &&
      password!.isNotEmpty &&
      passwordConfirm != null &&
      passwordConfirm!.isNotEmpty &&
      password == passwordConfirm;

  bool get isStep2Valid =>
      username != null &&
      username!.isNotEmpty &&
      name != null &&
      name!.isNotEmpty &&
      phoneNumber != null &&
      phoneNumber!.isNotEmpty &&
      buildingId != null &&
      buildingId!.isNotEmpty;

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
    };
  }
}

class SignupFormNotifier extends StateNotifier<SignupFormState> {
  SignupFormNotifier() : super(const SignupFormState());

  void updateStep1Data({
    required String dong,
    required String hosu,
    required String password,
    required String passwordConfirm,
  }) {
    state = state.copyWith(
      dong: dong.trim(),
      hosu: hosu.trim(),
      password: password,
      passwordConfirm: passwordConfirm,
    );
  }

  void updateStep2Data({
    required String username,
    required String name,
    required String phoneNumber,
    required String buildingId,
  }) {
    state = state.copyWith(
      username: username.trim(),
      name: name.trim(),
      phoneNumber: phoneNumber.trim(),
      buildingId: buildingId.trim(),
    );
  }

  void nextStep() {
    if (state.currentStep < 2) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setStep(int step) {
    if (step >= 1 && step <= 2) {
      state = state.copyWith(currentStep: step);
    }
  }

  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  void reset() {
    state = const SignupFormState();
  }

  String generateUsername() {
    if (state.dong != null && state.hosu != null) {
      // 동/호수를 조합해서 username 생성 (예: "101동1001호" -> "101_1001")
      final dongNumber = state.dong!.replaceAll(RegExp(r'[^0-9]'), '');
      final hosuNumber = state.hosu!.replaceAll(RegExp(r'[^0-9]'), '');
      return '${dongNumber}_$hosuNumber';
    }
    return '';
  }
}

final signupFormProvider = StateNotifierProvider<SignupFormNotifier, SignupFormState>((ref) {
  return SignupFormNotifier();
});
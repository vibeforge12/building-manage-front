import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/signup_form_provider.dart';
import 'package:building_manage_front/shared/widgets/signUp.dart';

class ResidentSignupStep3 extends ConsumerStatefulWidget {
  final VoidCallback onPrevious;
  final VoidCallback onComplete;

  const ResidentSignupStep3({
    super.key,
    required this.onPrevious,
    required this.onComplete,
  });

  @override
  ConsumerState<ResidentSignupStep3> createState() => _ResidentSignupStep3State();
}

class _ResidentSignupStep3State extends ConsumerState<ResidentSignupStep3> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // 기존 데이터가 있다면 컨트롤러에 설정
    final formData = ref.read(signupFormProvider);
    _nameController.text = formData.name ?? '';
    _phoneController.text = formData.phoneNumber ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    if (_formKey.currentState?.validate() ?? false) {
      // 3단계 데이터를 상태에 저장
      final formData = ref.read(signupFormProvider);
      final formNotifier = ref.read(signupFormProvider.notifier);

      ref.read(signupFormProvider.notifier).updateStep2Data(
        username: formNotifier.generateUsername(), // 자동 생성된 아이디 사용
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        buildingId: formData.buildingId ?? '', // 기존 buildingId 유지
      );

      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 이름 입력
            CommonInputField(
              label: '이름',
              hint: '이름을 입력해주세요',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 전화번호 입력
            CommonInputField(
              label: '전화번호',
              hint: '전화번호를 입력해주세요',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '전화번호를 입력해주세요';
                }
                if (!RegExp(r'^[0-9-]+$').hasMatch(value)) {
                  return '올바른 전화번호 형식을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),

            // 다음 버튼
            Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE8EEF2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: _handleComplete,
                child: const Text(
                  '다음',
                  style: TextStyle(
                    color: Color(0xFFA4ADB2),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
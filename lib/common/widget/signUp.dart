import 'package:flutter/material.dart';

/// 공용 입력 필드 위젯
class CommonInputField extends StatelessWidget {
  final String label; // 필드 상단 레이블
  final String hint; // 힌트 텍스트
  final TextEditingController controller;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final bool obscureText;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleVisibility;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final bool showVisibilityToggle;

  const CommonInputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.obscureText = false,
    this.validator,
    this.onToggleVisibility,
    this.onChanged,
    this.onFieldSubmitted,
    this.showVisibilityToggle = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          decoration: InputDecoration(
            hintText: hint,
            // ✅ 인풋 필드 스타일 (Figma 기준)
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // ← 높이 제어
            isDense: true, // ← 내부 여백 줄이기 (compact 모드)
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8), // ← radius 8px
              borderSide: const BorderSide(
                color: Color(0xFFEBEEF2), // ← 테두리 색
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEBEEF2),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFFEBEEF2),
                width: 1.2,
              ),
            ),
            suffixIcon: showVisibilityToggle
                ? IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: onToggleVisibility,
            )
                : null,
          ),
          validator: validator,
          onChanged: onChanged,
          onFieldSubmitted: onFieldSubmitted,
        ),
      ],
    );
  }
}

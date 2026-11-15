import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/error_message.dart';
import '../../../../shared/widgets/common_app_bar.dart';
import '../../data/repositories/username_recovery_repository.dart';
import '../../domain/usecases/recover_username.dart';

class UsernameRecoveryScreen extends ConsumerStatefulWidget {
  const UsernameRecoveryScreen({super.key});
  @override
  ConsumerState<UsernameRecoveryScreen> createState() =>
      _UsernameRecoveryScreenState();
}

class _UsernameRecoveryScreenState
    extends ConsumerState<UsernameRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _code = TextEditingController();
  UsernameChallenge? _challenge;
  List<RecoveredAccount>? _accounts;
  DateTime? _resendAt;
  Timer? _timer;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _phone.dispose();
    _code.dispose();
    super.dispose();
  }

  int get _resendSeconds =>
      (_resendAt?.difference(DateTime.now()).inSeconds ?? 0).clamp(0, 60);
  int get _remainingSeconds =>
      (_challenge?.expiresAt.difference(DateTime.now()).inSeconds ?? 0).clamp(
        0,
        300,
      );

  Future<void> _request() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final challenge = await ref
          .read(recoverUsernameProvider)
          .request(_name.text, _phone.text);
      if (!mounted) return;
      setState(() {
        _challenge = challenge;
        _code.clear();
        _resendAt = DateTime.now().add(
          Duration(seconds: challenge.retryAfterSeconds),
        );
      });
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userMessageOf(error, fallback: '인증번호를 보내지 못했습니다. 다시 시도해 주세요.');
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verify() async {
    if (_busy) return;
    if (!RegExp(r'^[0-9]{6}$').hasMatch(_code.text)) {
      setState(() => _error = '인증번호 6자리를 입력해 주세요.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final accounts = await ref
          .read(recoverUsernameProvider)
          .verify(_challenge!.id, _code.text);
      if (!mounted) return;
      _timer?.cancel();
      setState(() => _accounts = accounts);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = userMessageOf(
          error,
          fallback: '인증번호를 확인하지 못했습니다. 다시 시도해 주세요.',
        );
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _challenge = null;
      _accounts = null;
      _resendAt = null;
      _code.clear();
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = _accounts;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: commonAppBar('아이디 찾기'),
      body: SafeArea(
        child: Form(
          key: _form,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              if (accounts == null) ...[
                const Text(
                  '가입하신 정보를 입력해 주세요',
                  style: _headingStyle,
                ),
                const SizedBox(height: 8),
                const Text(
                  '가입할 때 등록한 이름과 휴대폰 번호로\n아이디를 확인할 수 있습니다.',
                  style: _descriptionStyle,
                ),
                const SizedBox(height: 32),
                _RecoveryField(
                  fieldKey: const ValueKey('recoveryName'),
                  label: '이름',
                  hint: '이름을 입력하세요',
                  controller: _name,
                  enabled: !_busy && _challenge == null,
                  maxLength: 120,
                  textInputAction: TextInputAction.next,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '이름을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 24),
                _RecoveryField(
                  fieldKey: const ValueKey('recoveryPhone'),
                  label: '휴대폰 번호',
                  hint: '휴대폰 번호를 입력하세요',
                  controller: _phone,
                  enabled: !_busy && _challenge == null,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11,
                  validator: (value) =>
                      RegExp(r'^01[0-9]{8,9}$').hasMatch(value ?? '')
                          ? null
                          : '휴대폰 번호를 확인해 주세요.',
                ),
                const SizedBox(height: 16),
                _RecoveryButton(
                  onPressed: _busy || _resendSeconds > 0 ? null : _request,
                  secondary: _challenge != null,
                  loading: _busy && _challenge == null,
                  label: _resendSeconds > 0
                      ? '재전송까지 $_resendSeconds초'
                      : _challenge == null
                          ? '인증번호 받기'
                          : '인증번호 다시 받기',
                ),
                if (_challenge != null) ...[
                  const SizedBox(height: 32),
                  _RecoveryField(
                    fieldKey: const ValueKey('recoveryCode'),
                    label: '인증번호',
                    hint: '인증번호 6자리를 입력하세요',
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _remainingSeconds > 0
                        ? '남은 시간 ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'
                        : '인증 시간이 지났습니다. 인증번호를 다시 받아 주세요.',
                    style: _descriptionStyle.copyWith(
                      fontSize: 12,
                      color: _remainingSeconds > 0
                          ? _primaryColor
                          : const Color(0xFFD32F2F),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _RecoveryButton(
                    onPressed: _busy || _remainingSeconds == 0 ? null : _verify,
                    loading: _busy,
                    label: '아이디 확인',
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy ? null : _reset,
                    style: _secondaryTextButtonStyle,
                    child: const Text('이름·휴대폰 번호 다시 입력'),
                  ),
                ],
              ] else ...[
                Text(
                  accounts.isEmpty ? '입력하신 정보와 일치하는 계정이 없습니다.' : '가입하신 아이디입니다.',
                  style: _headingStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  accounts.isEmpty
                      ? '가입할 때 입력한 이름과 휴대폰 번호를 다시 확인해 주세요.'
                      : '건물과 아이디를 확인한 뒤 로그인해 주세요.',
                  style: _descriptionStyle,
                ),
                const SizedBox(height: 32),
                for (final account in accounts)
                  _RecoveredAccountCard(
                    account: account,
                    onLogin: () => context.pop(account.username),
                  ),
                TextButton(
                  onPressed: _reset,
                  style: _secondaryTextButtonStyle,
                  child: const Text('다시 찾기'),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      _error!,
                      style: _descriptionStyle.copyWith(
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

const _primaryColor = Color(0xFF006FFF);
const _textColor = Color(0xFF17191A);
const _mutedColor = Color(0xFF757B80);
const _headingStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontSize: 18,
  fontWeight: FontWeight.w700,
  height: 1.5,
  color: _textColor,
);
const _descriptionStyle = TextStyle(
  fontFamily: 'Pretendard',
  fontSize: 14,
  height: 1.5,
  color: _mutedColor,
);
final _secondaryTextButtonStyle = TextButton.styleFrom(
  foregroundColor: _mutedColor,
  minimumSize: const Size(48, 48),
  textStyle: _descriptionStyle,
);

class _RecoveryField extends StatelessWidget {
  const _RecoveryField({
    required this.fieldKey,
    required this.label,
    required this.hint,
    required this.controller,
    required this.enabled,
    required this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.autofillHints,
    this.validator,
    this.textInputAction = TextInputAction.done,
  });

  final Key fieldKey;
  final String label;
  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final int maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final FormFieldValidator<String>? validator;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide.none,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: _descriptionStyle.copyWith(
            color: _textColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          key: fieldKey,
          controller: controller,
          enabled: enabled,
          maxLength: maxLength,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          autofillHints: autofillHints,
          textInputAction: textInputAction,
          validator: validator,
          style: _descriptionStyle.copyWith(
            fontSize: 16,
            color: enabled ? _textColor : _mutedColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: _descriptionStyle.copyWith(fontSize: 16),
            counterText: '',
            filled: true,
            fillColor:
                enabled ? const Color(0xFFF2F8FC) : const Color(0xFFE8EEF2),
            contentPadding: const EdgeInsets.all(16),
            border: border,
            enabledBorder: border,
            disabledBorder: border,
            focusedBorder: border.copyWith(
              borderSide: const BorderSide(color: _primaryColor),
            ),
            errorBorder: border.copyWith(
              borderSide: const BorderSide(color: Color(0xFFD32F2F)),
            ),
            focusedErrorBorder: border.copyWith(
              borderSide: const BorderSide(color: Color(0xFFD32F2F)),
            ),
            errorStyle: _descriptionStyle.copyWith(
              fontSize: 12,
              color: const Color(0xFFD32F2F),
            ),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

class _RecoveryButton extends StatelessWidget {
  const _RecoveryButton({
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: secondary ? const Color(0xFFE8EEF2) : _primaryColor,
        foregroundColor: secondary ? _textColor : Colors.white,
        disabledBackgroundColor: const Color(0xFFE8EEF2),
        disabledForegroundColor: _mutedColor,
        minimumSize: const Size.fromHeight(56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontFamily: 'Pretendard',
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      child: loading
          ? Semantics(
              label: '처리 중',
              child: const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _primaryColor,
                ),
              ),
            )
          : Text(label, textAlign: TextAlign.center),
    );
  }
}

class _RecoveredAccountCard extends StatelessWidget {
  const _RecoveredAccountCard({required this.account, required this.onLogin});

  final RecoveredAccount account;
  final VoidCallback onLogin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EEF2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (account.buildingName.isNotEmpty) ...[
              Text(account.buildingName, style: _descriptionStyle),
              const SizedBox(height: 8),
            ],
            SelectableText(account.username, style: _headingStyle),
            const SizedBox(height: 24),
            _RecoveryButton(label: '이 아이디로 로그인', onPressed: onLogin),
          ],
        ),
      ),
    );
  }
}

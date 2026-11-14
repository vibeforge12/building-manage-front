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
            padding: const EdgeInsets.all(24),
            children: [
              if (accounts == null) ...[
                const Text('가입할 때 등록한 이름과 휴대폰 번호를 입력해 주세요.'),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  enabled: !_busy && _challenge == null,
                  maxLength: 120,
                  decoration: const InputDecoration(
                    labelText: '이름',
                    counterText: '',
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? '이름을 입력해 주세요.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  enabled: !_busy && _challenge == null,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  maxLength: 11,
                  decoration: const InputDecoration(
                    labelText: '휴대폰 번호',
                    counterText: '',
                  ),
                  validator: (value) =>
                      RegExp(r'^01[0-9]{8,9}$').hasMatch(value ?? '')
                      ? null
                      : '휴대폰 번호를 확인해 주세요.',
                ),
                const SizedBox(height: 20),
                OutlinedButton(
                  onPressed: _busy || _resendSeconds > 0 ? null : _request,
                  child: Text(
                    _resendSeconds > 0
                        ? '재전송까지 $_resendSeconds초'
                        : _challenge == null
                        ? '인증번호 받기'
                        : '인증번호 다시 받기',
                  ),
                ),
                if (_challenge != null) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _code,
                    enabled: !_busy,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    autofillHints: const [AutofillHints.oneTimeCode],
                    maxLength: 6,
                    decoration: const InputDecoration(
                      labelText: '인증번호',
                      counterText: '',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _remainingSeconds > 0
                        ? '남은 시간 ${_remainingSeconds ~/ 60}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}'
                        : '인증 시간이 지났습니다. 인증번호를 다시 받아 주세요.',
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy || _remainingSeconds == 0 ? null : _verify,
                    child: const Text('아이디 확인'),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _reset,
                    child: const Text('이름·휴대폰 번호 다시 입력'),
                  ),
                ],
              ] else ...[
                Text(
                  accounts.isEmpty ? '입력하신 정보와 일치하는 계정이 없습니다.' : '가입하신 아이디입니다.',
                ),
                const SizedBox(height: 16),
                for (final account in accounts)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (account.buildingName.isNotEmpty)
                            Text(account.buildingName),
                          SelectableText(
                            account.username,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          FilledButton(
                            onPressed: () => context.pop(account.username),
                            child: const Text('이 아이디로 로그인'),
                          ),
                        ],
                      ),
                    ),
                  ),
                TextButton(onPressed: _reset, child: const Text('다시 찾기')),
              ],
              if (_busy)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
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

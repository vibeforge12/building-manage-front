import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/start_app_update.dart';
import 'update_actions.dart';

class AppUpdateButton extends ConsumerStatefulWidget {
  const AppUpdateButton({
    super.key,
    required this.platform,
    required this.storeUrl,
    required this.targetBuild,
  });
  final String platform;
  final Uri storeUrl;
  final int targetBuild;

  @override
  ConsumerState<AppUpdateButton> createState() => _AppUpdateButtonState();
}

class _AppUpdateButtonState extends ConsumerState<AppUpdateButton> {
  bool _busy = false;
  bool _storeFallback = false;

  Future<void> _update({bool storeOnly = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    var result = UpdateLaunchResult.unavailable;
    try {
      if (storeOnly) {
        result = await ref.read(openUpdateStoreProvider)(widget.storeUrl)
            ? UpdateLaunchResult.started
            : UpdateLaunchResult.unavailable;
      } else {
        result = await ref
            .read(startAppUpdateProvider)
            .execute(widget.platform, widget.storeUrl, widget.targetBuild);
      }
    } catch (_) {
      result = UpdateLaunchResult.unavailable;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _storeFallback =
          result == UpdateLaunchResult.unavailable &&
          widget.platform == 'android';
    });
    final String? message = switch (result) {
      UpdateLaunchResult.busy => '업데이트를 확인 중입니다. 잠시 후 다시 시도해 주세요.',
      UpdateLaunchResult.cancelled => '업데이트를 취소했습니다. 원할 때 다시 진행할 수 있습니다.',
      UpdateLaunchResult.unavailable =>
        widget.platform == 'android' && !storeOnly
            ? '앱 내 업데이트를 시작하지 못했습니다. 다시 시도하거나 Play 스토어에서 확인해 주세요.'
            : '스토어를 열지 못했습니다. 잠시 후 다시 시도해 주세요.',
      _ => null,
    };
    if (message != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      FilledButton(
        onPressed: _busy ? null : _update,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF006FFF),
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        child: Text(_busy ? '업데이트 준비 중…' : '업데이트하기'),
      ),
      if (_storeFallback)
        TextButton(
          onPressed: _busy ? null : () => _update(storeOnly: true),
          child: const Text('Play 스토어에서 확인'),
        ),
    ],
  );
}

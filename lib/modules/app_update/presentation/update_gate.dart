import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../data/update_repository.dart';
import '../domain/check_update.dart';
import '../domain/update_policy.dart';

final checkUpdateProvider = Provider(
  (ref) => CheckUpdate(
    StoredUpdateRepository(
      UpdateRemoteDataSource(ref.watch(apiClientProvider)),
      '${AppConfig.environment}:${AppConfig.apiBaseUrl}',
    ),
  ),
);
final updateIdentityProvider = Provider<Future<(String, int)> Function()>(
  (ref) => () async {
    final info = await PackageInfo.fromPlatform().timeout(
      const Duration(seconds: 3),
    );
    final platform = defaultTargetPlatform == TargetPlatform.android
        ? 'android'
        : defaultTargetPlatform == TargetPlatform.iOS
        ? 'ios'
        : '';
    return (kIsWeb ? '' : platform, int.parse(info.buildNumber));
  },
);
final openUpdateStoreProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);

class UpdateGateState {
  final bool loading;
  final UpdatePolicy? requiredPolicy;
  const UpdateGateState({this.loading = true, this.requiredPolicy});
}

final updateGateProvider =
    NotifierProvider<UpdateGateNotifier, UpdateGateState>(
      UpdateGateNotifier.new,
    );

class UpdateGateNotifier extends Notifier<UpdateGateState> {
  bool _busy = false;
  bool _alive = true;
  @override
  UpdateGateState build() {
    ref.onDispose(() => _alive = false);
    return const UpdateGateState();
  }

  Future<void> check() async {
    if (_busy) return;
    _busy = true;
    try {
      final (platform, build) = await ref.read(updateIdentityProvider)();
      final policy = platform.isEmpty
          ? null
          : await ref.read(checkUpdateProvider).execute(platform);
      if (!_alive) return;
      state = UpdateGateState(
        loading: false,
        requiredPolicy: policy == null
            ? state.requiredPolicy
            : policy.requiresUpdate(build)
            ? policy
            : null,
      );
    } catch (_) {
      if (!_alive) return;
      // A check failure never clears a previously confirmed mandatory update.
      state = UpdateGateState(
        loading: false,
        requiredPolicy: state.requiredPolicy,
      );
    } finally {
      _busy = false;
    }
  }
}

class AppUpdateGate extends ConsumerStatefulWidget {
  final Widget child;
  const AppUpdateGate({super.key, required this.child});
  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      if (mounted) ref.read(updateGateProvider.notifier).check();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(updateGateProvider.notifier).check();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(updateGateProvider);
    if (state.loading) {
      return const ColoredBox(
        color: Colors.white,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.requiredPolicy == null) return widget.child;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.system_update,
                    color: Color(0xFF006FFF),
                    size: 48,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    '업데이트가 필요합니다',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '원활한 서비스 이용을 위해\n최신 버전으로 업데이트해 주세요.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                      color: Color(0xFF757B80),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: () async {
                      bool opened = false;
                      try {
                        opened = await ref.read(openUpdateStoreProvider)(
                          state.requiredPolicy!.storeUrl!,
                        );
                      } catch (_) {
                        /* Show a recoverable action failure. */
                      }
                      if (!context.mounted || opened) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('스토어를 열지 못했습니다. 잠시 후 다시 시도해 주세요.'),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF006FFF),
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text(
                      '업데이트하기',
                      style: TextStyle(fontFamily: 'Pretendard'),
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        ref.read(updateGateProvider.notifier).check(),
                    child: const Text('다시 확인'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

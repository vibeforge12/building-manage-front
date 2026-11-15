import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/google_play_updater.dart';
import '../domain/start_app_update.dart';

final openUpdateStoreProvider = Provider<Future<bool> Function(Uri)>(
  (ref) =>
      (url) => launchUrl(url, mode: LaunchMode.externalApplication),
);
final androidAppUpdaterProvider = Provider<AndroidAppUpdater>(
  (ref) => GooglePlayUpdater(),
);
final startAppUpdateProvider = Provider(
  (ref) => StartAppUpdate(
    ref.watch(androidAppUpdaterProvider),
    ref.watch(openUpdateStoreProvider),
  ),
);

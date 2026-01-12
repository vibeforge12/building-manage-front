import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:building_manage_front/app/app.dart';
import 'package:building_manage_front/core/network/api_client.dart';
import 'package:building_manage_front/core/network/interceptors/auth_interceptor.dart';
import 'firebase_options.dart';

/// 백그라운드에서 FCM 메시지 처리
/// 앱이 종료되거나 백그라운드에 있을 때 실행
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 백그라운드 핸들러에서는 최소한의 작업만 수행
  // Firebase는 이미 초기화되어 있을 수 있으므로 조건부 초기화
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
  } catch (e) {
    // Firebase 이미 초기화됨 - 무시
  }

  // Background message handling
}

void main() async {
  // Flutter 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();

  // Release 모드에서 빨간 에러 화면 숨기기
  FlutterError.onError = (FlutterErrorDetails details) {
    // 에러는 기록하지만 빨간 화면은 표시하지 않음
    FlutterError.dumpErrorToConsole(details);
  };

  String? initError;

  // 환경 변수 로드 (실패해도 앱 실행)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    // .env file load failed, using defaults
  }

  // Firebase 초기화 (실패해도 앱 실행)
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // FCM 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  } catch (e) {
    initError = 'Firebase 초기화 실패';
    // Firebase 실패해도 앱은 실행 (FCM 기능만 비활성화)
  }

  // API 클라이언트 초기화 (실패해도 앱 실행)
  try {
    ApiClient().initialize();
  } catch (e) {
    initError = initError ?? 'API 초기화 실패';
    // API 실패해도 앱은 실행 (오프라인 모드)
  }

  // 앱 첫 실행 감지 및 토큰 초기화
  try {
    await _clearTokensOnFirstRun();
  } catch (e) {
    // 토큰 초기화 실패해도 앱은 실행
  }

  // 앱 실행 (초기화 에러가 있어도 실행)
  runApp(
    ProviderScope(
      child: BuildingManageApp(initError: initError),
    ),
  );
}

/// 앱 첫 실행 시 저장된 토큰 삭제
/// SharedPreferences로 앱 버전을 저장하여 첫 실행 여부 판단
Future<void> _clearTokensOnFirstRun() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    const currentVersion = '1.0.1'; // ⚠️ 버전 변경 시 토큰 강제 삭제
    final savedVersion = prefs.getString('app_version');

    // 앱 버전이 다르거나 처음 실행인 경우
    if (savedVersion != currentVersion) {
      await AuthInterceptor.clearToken();
      await prefs.setString('app_version', currentVersion);
    }
  } catch (e) {
    // 토큰 초기화 실패 무시
  }
}

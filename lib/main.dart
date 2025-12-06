import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:building_manage_front/app/app.dart';
import 'package:building_manage_front/core/network/api_client.dart';
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

  print('🔔 백그라운드 메시지 처리: ${message.notification?.title}');
  print('📋 데이터: ${message.data}');
}

void main() async {
  // Flutter 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  // 환경 변수 로드 (실패해도 앱 실행)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('⚠️ .env 파일 로드 실패 (기본값 사용): $e');
    // .env 파일 없어도 앱은 실행
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
    print('⚠️ Firebase 초기화 실패: $e');
    initError = 'Firebase 초기화 실패';
    // Firebase 실패해도 앱은 실행 (FCM 기능만 비활성화)
  }

  // API 클라이언트 초기화 (실패해도 앱 실행)
  try {
    ApiClient().initialize();
  } catch (e) {
    print('⚠️ API 클라이언트 초기화 실패: $e');
    initError = initError ?? 'API 초기화 실패';
    // API 실패해도 앱은 실행 (오프라인 모드)
  }

  // 앱 실행 (초기화 에러가 있어도 실행)
  runApp(
    ProviderScope(
      child: BuildingManageApp(initError: initError),
    ),
  );
}

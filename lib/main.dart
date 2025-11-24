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
  // Firebase 초기화 (백그라운드에서)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  print('🔔 백그라운드 메시지 처리: ${message.notification?.title}');
  print('📋 데이터: ${message.data}');

  // 여기서 백그라운드 작업 처리 가능
  // 예: 데이터베이스 저장, 상태 업데이트 등
}

void main() async {
  // Flutter 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 환경 변수 로드
    await dotenv.load(fileName: ".env");

    // Firebase 초기화
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FCM 백그라운드 메시지 핸들러 등록
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // API 클라이언트 초기화
    ApiClient().initialize();

    // 앱 실행
    runApp(
      const ProviderScope(
        child: BuildingManageApp(),
      ),
    );
  } catch (e) {
    // 초기화 실패 시 에러 표시
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('앱 초기화 실패: $e'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // 앱 재시작 (실제로는 앱을 다시 열어야 함)
                    main();
                  },
                  child: const Text('다시 시도'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:building_manage_front/app/app.dart';
import 'package:building_manage_front/core/network/api_client.dart';

void main() async {
  // Flutter 바인딩 보장
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 환경 변수 로드
    await dotenv.load(fileName: ".env");

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

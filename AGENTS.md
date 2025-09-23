# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소의 코드로 작업할 때 지침을 제공합니다.

## 프로젝트 개요

이것은 "building_manage_front"라는 이름의 Flutter 애플리케이션으로, 건물 관리 프론트엔드 애플리케이션입니다. Android, iOS, Web, Linux, macOS, Windows를 지원하는 크로스 플랫폼 앱입니다. 단일 앱 안에서 *유저*, *건물별 관리자*, *담당자*, *본사* 등 네 가지 로그인 역할을 지원하며, 로그인 유형에 따라 화면과 기능이 분기되는 구조를 목표로 합니다.

## 개발 명령어

### 설정
```bash
flutter pub get                    # 의존성 설치
```

### 개발
```bash
flutter run                       # 연결된 기기/에뮬레이터에서 실행
flutter run -d chrome             # Chrome(웹)에서 실행
flutter run -d macos              # macOS에서 실행
flutter run --hot                 # 핫 리로드 활성화하여 실행
flutter hot-reload                # 개발 중 핫 리로드 실행
flutter hot-restart               # 개발 중 핫 리스타트 실행
```

### 빌드
```bash
flutter build apk                 # Android APK 빌드
flutter build appbundle           # Android App Bundle 빌드
flutter build ios                 # iOS 앱 빌드
flutter build web                 # 웹 앱 빌드
flutter build macos               # macOS 앱 빌드
flutter build windows             # Windows 앱 빌드
flutter build linux               # Linux 앱 빌드
```

### 테스트 및 품질 관리
```bash
flutter test                      # 모든 테스트 실행
flutter test test/widget_test.dart # 특정 테스트 파일 실행
flutter analyze                   # 정적 분석 실행
flutter pub deps                  # 의존성 트리 표시
flutter pub outdated              # 오래된 의존성 확인
flutter pub upgrade               # 의존성 업그레이드
```

### 플랫폼별 명령어
```bash
flutter devices                   # 사용 가능한 기기/에뮬레이터 목록
flutter emulators                 # 사용 가능한 에뮬레이터 목록
flutter emulators --launch <id>   # 특정 에뮬레이터 실행
flutter clean                     # 빌드 캐시 정리
```

## 아키텍처

### 프로젝트 구조
- `lib/main.dart` - MyApp과 MyHomePage 위젯이 있는 메인 애플리케이션 진입점
- `test/` - 위젯 테스트와 기타 테스트 파일들 포함
- `android/`, `ios/`, `web/`, `linux/`, `macos/`, `windows/` - 플랫폼별 설정
- `pubspec.yaml` - Flutter 의존성 및 프로젝트 설정
- `analysis_options.yaml` - flutter_lints를 사용한 Dart 분석기 설정

### 현재 구현 상태
현재 앱은 기본적인 Flutter 카운터 데모 애플리케이션을 포함하고 있습니다:
- 진보라색 컬러 스킴을 사용하는 Material Design 테마
- 증가 기능이 있는 상태 저장 카운터 위젯
- 표준 Flutter 프로젝트 구조 및 규칙

앞으로는 공용 로그인 화면을 통해 네 가지 역할 중 하나를 선택하거나 자동으로 인식하여 적절한 홈 화면 및 권한 세트로 이동시키는 분기 로직을 구현할 예정입니다. 이 때 역할별 대시보드와 기능 모듈(예: 시설 점검, 공지 관리, 본사 리포트 등)은 동일한 코드베이스에서 조건부로 로드되도록 설계합니다.

### 의존성
- **flutter_lints ^5.0.0** - Flutter 권장 린팅 규칙 제공
- **cupertino_icons ^1.0.8** - iOS 스타일 아이콘
- **flutter_test** - 테스팅 프레임워크

## 코드 표준
- `package:flutter_lints/flutter.yaml`을 통한 Flutter 권장 린트 사용
- Dart SDK 버전: ^3.8.1
- Flutter/Dart 명명 규칙 및 코드 스타일 준수
- 적절한 곳에서 const 생성자 사용
- 앱이 성장함에 따라 적절한 상태 관리 패턴 구현

## 플랫폼 지원
다음을 지원하는 멀티 플랫폼 Flutter 애플리케이션입니다:
- **Android** (android/ 디렉터리를 통해)
- **iOS** (ios/ 디렉터리를 통해)
- **Web** (manifest.json과 index.html이 있는 web/ 디렉터리를 통해)
- **Desktop**: Linux, macOS, Windows (각각의 디렉터리를 통해)

각 플랫폼은 플랫폼별 설정과 빌드 구성이 있는 자체 설정 디렉터리를 가지고 있습니다.

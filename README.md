# Building Manage Front

다중 역할 기반의 건물 관리 서비스를 위한 Flutter 프론트엔드 애플리케이션입니다. 하나의 코드베이스에서 유저, 건물별 관리자, 담당자, 본사 4가지 역할을 지원하며, 플랫폼 전반의 업무 흐름을 모바일·웹에서 일관되게 제공합니다.

## 프로젝트 특징
- **역할별 로그인 플로우**: 공용 홈 화면에서 각 역할에 맞는 로그인 화면으로 이동하며, 입력 항목과 권한이 역할마다 분기됩니다.
- **재사용 가능한 UI 컴포넌트**: 화면 헤더(`PageHeaderText`), 배경(`FullScreenImageBackground`), 주요 버튼 등을 위젯으로 모듈화하여 일관된 디자인을 유지합니다.
- **멀티 플랫폼 지원**: Android, iOS, Web, macOS, Windows, Linux 환경에서 동일한 기능을 제공하도록 설계되었습니다.
- **확장 가능한 구조**: `features` 디렉터리 기준으로 도메인 단위 폴더링을 적용해 역할별 화면과 공통 컴포넌트를 분리했습니다.

## 기술 스택
- **프레임워크**: Flutter 3.x (Dart SDK ^3.8.1)
- **UI**: Material 3, 커스텀 공통 위젯
- **품질 도구**: `flutter_lints`, `flutter_test`

## 디렉터리 개요
```
lib/
├─ app/                     # 앱 전역 설정 및 부트스트랩 코드
├─ core/                    # 공통 상수, 유틸, 서비스 계층
├─ features/
│   ├─ auth/                # 역할별 로그인 화면 및 로직
│   ├─ common/              # 재사용 가능한 위젯/레이아웃
│   ├─ landing/             # 메인 홈 화면
│   └─ registration/        # 회원가입 관련 화면
├─ main.dart                # 앱 진입점
```
그 외 플랫폼별 설정(`android/`, `ios/`, `web/` 등)과 문서(`docs/`), 테스트 코드(`test/`)가 포함되어 있습니다.

## 개발 환경 준비
1. [Flutter 설치](https://docs.flutter.dev/get-started/install) 및 `flutter doctor`로 환경 확인
2. 저장소 클론 후 의존성 설치
   ```bash
   flutter pub get
   ```

## 실행 방법
- 연결된 기기 또는 에뮬레이터에서 실행
  ```bash
  flutter run
  ```
- 특정 플랫폼
  ```bash
  flutter run -d chrome   # Web
  flutter run -d macos    # macOS
  ```

## 품질 관리
```bash
flutter analyze            # 정적 분석
flutter test               # 위젯 및 단위 테스트
```
필요 시 `flutter clean`으로 빌드 캐시를 정리하고, `flutter pub outdated`로 의존성 최신 상태를 확인합니다.

## UI 가이드 요약
- 헤더 텍스트는 항상 `PageHeaderText` 위젯을 사용하며 색상 `#464A4D`, 크기 16, 굵기 700을 유지합니다.
- 역할 선택 및 로그인 화면은 배경 이미지/단색 배경을 명확히 구분하고, 버튼과 입력 필드는 Material 3 스타일을 준수합니다.
- 세부 UI 규칙과 화면 진행 계획은 `docs/ui_navigation_plan.md`에 기록합니다.

## 향후 확장 계획
- 실제 백엔드 API 연동 및 인증 로직 구현
- 역할별 대시보드, 시설 점검, 공지 관리 등 업무 모듈 추가
- 상태 관리 도입(예: Riverpod, Bloc 등) 및 공용 비즈니스 로직 정리

문의나 제안은 이슈 트래커를 통해 전달해 주세요. 프로젝트의 구조나 디자인 가이드는 문서를 참고하며 지속적으로 업데이트됩니다.

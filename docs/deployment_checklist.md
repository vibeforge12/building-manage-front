> ⚠️ **폐기 예정 문서 (2026-08-21)**
> 이 문서는 현재 코드와 일치하지 않습니다. 참고하지 마세요.
> 유효한 문서: `docs/프론트엔드_구조_및_문제점_분석.md`, `CLAUDE.md`

# 앱 배포 준비 체크리스트

## 현재 앱 정보

- **앱 이름**: building_manage_front (Building Manage Front)
- **현재 버전**: 1.0.0+1
- **Android Package**: com.example.building_manage_front
- **iOS Bundle ID**: (Project settings에서 확인 필요)

---

## ✅ Android 배포 준비

### 1. 권한 설정 (AndroidManifest.xml) ✅

**현재 설정된 권한:**
- ✅ `READ_EXTERNAL_STORAGE` - 이미지 선택
- ✅ `CAMERA` - 사진 촬영

**추가 권장 권한:**
```xml
<!-- AndroidManifest.xml에 추가 권장 -->
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
                 android:maxSdkVersion="32"/>
```

### 2. 앱 서명 (Signing) ⚠️ 필수

**현재 상태:** DEBUG 서명 사용 중 (배포 불가)

**프로덕션 배포를 위한 설정 필요:**

#### 2-1. Keystore 생성
```bash
keytool -genkey -v -keystore ~/building-manage-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias building-manage-key
```

#### 2-2. key.properties 파일 생성
`android/key.properties` 파일 생성:
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=building-manage-key
storeFile=<keystore-파일-경로>
```

#### 2-3. build.gradle.kts 수정
```kotlin
// android/app/build.gradle.kts

// 파일 상단에 추가
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    // ...

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            // ProGuard 설정 (선택사항)
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

### 3. 앱 ID 변경 ⚠️ 권장

**현재:** `com.example.building_manage_front`
**변경 필요:** `com.vibeforge.buildingmanage` (또는 회사 도메인에 맞게)

**변경 방법:**
1. `android/app/build.gradle.kts`에서 `applicationId` 변경
2. `android/app/src/main/AndroidManifest.xml`에서 `package` 변경
3. `android/app/src/main/kotlin/` 폴더 구조 변경

### 4. ProGuard 규칙 설정

`android/app/proguard-rules.pro` 파일 생성:
```proguard
# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Dio
-keep class com.squareup.okhttp3.** { *; }
-keep interface com.squareup.okhttp3.** { *; }
-dontwarn com.squareup.okhttp3.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
```

### 5. 빌드 명령어

```bash
# APK 빌드 (테스트용)
flutter build apk --release

# App Bundle 빌드 (Google Play Store 배포용 - 권장)
flutter build appbundle --release

# 특정 flavor 빌드 (설정된 경우)
flutter build appbundle --release --flavor production
```

---

## ✅ iOS 배포 준비

### 1. 권한 설정 (Info.plist) ✅

**현재 설정된 권한:**
- ✅ `NSPhotoLibraryUsageDescription` - 사진 라이브러리 접근
- ✅ `NSCameraUsageDescription` - 카메라 접근

**추가 권장 설명 (현재 설명 개선):**
- 현재 설명이 한글로 잘 작성되어 있음 ✅

### 2. Bundle Identifier 변경 ⚠️ 권장

**변경 필요:** Xcode에서 `com.example.buildingManageFront`를 회사 도메인으로 변경

**변경 방법:**
1. Xcode에서 `ios/Runner.xcworkspace` 열기
2. Runner 프로젝트 선택 → General 탭
3. Bundle Identifier 변경

### 3. App Icon 설정 ⚠️ 필수

**위치:** `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

**필요한 크기:**
- 20x20, 29x29, 40x40, 58x58, 60x60, 76x76, 80x80, 87x87, 120x120, 152x152, 167x167, 180x180, 1024x1024

**생성 도구:**
- [appicon.co](https://appicon.co/) - 자동 생성
- Xcode Asset Catalog

### 4. 앱 서명 (Signing) ⚠️ 필수

**Xcode 설정:**
1. Xcode에서 Runner 프로젝트 선택
2. Signing & Capabilities 탭
3. Team 선택 (Apple Developer Account 필요)
4. Automatically manage signing 체크

**필요한 것:**
- Apple Developer Program 가입 ($99/year)
- Provisioning Profile 생성
- Distribution Certificate 생성

### 5. 빌드 설정

**빌드 번호 증가:**
```bash
# 버전 1.0.0, 빌드 번호 2로 빌드
flutter build ios --release --build-number=2
```

**Archive 생성 (배포용):**
```bash
# 1. Flutter 빌드
flutter build ios --release

# 2. Xcode에서 Archive
# Xcode → Product → Archive
# 또는 명령줄:
xcodebuild -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/Runner.xcarchive \
  archive
```

---

## 🔧 공통 배포 준비

### 1. 환경 변수 보안 ⚠️ 중요

**`.env` 파일 제외 확인:**
```gitignore
# .gitignore에 있는지 확인
.env
*.env
```

**프로덕션 환경 설정:**
```env
# .env.production 파일 생성
API_BASE_URL=https://production-api.yourdomain.com
API_VERSION=v1
ENVIRONMENT=production
API_DEBUG=false
```

### 2. 앱 메타데이터 업데이트

**pubspec.yaml 확인:**
```yaml
name: building_manage_front
description: "건물 관리 애플리케이션"
version: 1.0.0+1  # 배포 시 증가

# 배포 전 확인 사항:
# - description을 사용자에게 보여줄 설명으로 변경
# - 버전 번호 정책 수립 (major.minor.patch+build)
```

**Android:**
- `android/app/src/main/AndroidManifest.xml`에서 `android:label` 변경

**iOS:**
- `Info.plist`에서 `CFBundleDisplayName` 확인 (현재: "Building Manage Front")

### 3. 아이콘 및 스플래시 스크린 ⚠️ 필수

**현재 상태:**
- Android: 기본 Flutter 아이콘 사용 중
- iOS: 기본 아이콘 사용 중

**설정 방법 (flutter_launcher_icons 사용):**

1. `pubspec.yaml`에 추가:
```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1

flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/icon/app_icon.png"  # 1024x1024 PNG
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
```

2. 실행:
```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

### 4. 코드 정리

**제거해야 할 것들:**
- ❌ Debug print 문 (~350개 발견됨)
- ❌ TODO 주석
- ❌ 테스트용 코드
- ❌ 미사용 import 문

**권장 작업:**
```bash
# Lint 검사
flutter analyze

# 코드 포맷팅
flutter format lib/

# 미사용 종속성 제거
flutter pub outdated
```

### 5. 성능 최적화

**체크리스트:**
- [ ] 이미지 최적화 (WebP 변환 고려)
- [ ] 불필요한 패키지 제거
- [ ] Code splitting 고려
- [ ] 초기 로딩 속도 최적화

### 6. 법적 준비사항

**필수 문서:**
- [ ] 개인정보 처리방침 (Privacy Policy)
- [ ] 서비스 이용약관 (Terms of Service)
- [ ] 오픈소스 라이선스 고지
- [ ] 위치 정보 수집 동의 (필요 시)

---

## 📱 스토어 등록 준비

### Google Play Store

**필요한 자료:**
1. 스크린샷 (최소 2개)
   - Phone: 최소 320px, 최대 3840px
   - 7인치 태블릿 (선택)
   - 10인치 태블릿 (선택)

2. Feature Graphic (1024 x 500px)

3. 앱 아이콘 (512 x 512px)

4. 앱 설명
   - 짧은 설명 (80자 이하)
   - 전체 설명 (4000자 이하)

5. 콘텐츠 등급 설정

6. 개인정보 처리방침 URL

### Apple App Store

**필요한 자료:**
1. 스크린샷
   - 6.5" Display: 1242 x 2688px 또는 1284 x 2778px
   - 5.5" Display: 1242 x 2208px

2. 앱 미리보기 영상 (선택)

3. 앱 아이콘 (1024 x 1024px)

4. 앱 설명
   - 부제목 (30자 이하)
   - 설명 (4000자 이하)
   - 프로모션 텍스트 (170자 이하)
   - 키워드 (100자 이하, 쉼표로 구분)

5. 지원 URL, 마케팅 URL, 개인정보 처리방침 URL

6. App Store 카테고리 선택

---

## 🚀 배포 명령어 요약

### Android (Google Play)

```bash
# 1. 버전 업데이트 (pubspec.yaml)
# version: 1.0.0+1 → 1.0.1+2

# 2. App Bundle 빌드
flutter build appbundle --release

# 3. 빌드 파일 위치
# build/app/outputs/bundle/release/app-release.aab

# 4. Google Play Console에 업로드
```

### iOS (App Store)

```bash
# 1. 버전 업데이트 (pubspec.yaml)

# 2. iOS 빌드
flutter build ios --release

# 3. Xcode에서 Archive
# Product → Archive → Distribute App

# 4. App Store Connect에 업로드
```

---

## ⚠️ 배포 전 최종 체크리스트

### 필수 사항
- [ ] 앱 ID 변경 (com.example.* → 실제 도메인)
- [ ] 앱 서명 설정 (Android Keystore, iOS Certificate)
- [ ] 앱 아이콘 설정
- [ ] 스플래시 스크린 설정
- [ ] 개인정보 처리방침 URL 준비
- [ ] .env 파일 git 제외 확인
- [ ] Debug print 문 제거
- [ ] 프로덕션 API 엔드포인트 설정

### 권장 사항
- [ ] ProGuard 설정 (Android)
- [ ] 앱 스크린샷 준비
- [ ] Feature Graphic 준비
- [ ] 앱 설명 작성
- [ ] 콘텐츠 등급 결정
- [ ] 베타 테스트 진행 (TestFlight, Internal Testing)
- [ ] 충돌 보고 도구 통합 (Firebase Crashlytics 등)
- [ ] 분석 도구 통합 (Firebase Analytics 등)

### 보안 체크
- [ ] API 키 환경 변수 처리
- [ ] 민감한 정보 암호화 (flutter_secure_storage 사용 확인)
- [ ] HTTPS 통신 확인
- [ ] 인증서 핀닝 고려
- [ ] SQL Injection 방지
- [ ] XSS 방지

---

## 📞 도움이 필요한 경우

### 리소스
- [Flutter 공식 배포 가이드](https://docs.flutter.dev/deployment)
- [Android 배포 가이드](https://docs.flutter.dev/deployment/android)
- [iOS 배포 가이드](https://docs.flutter.dev/deployment/ios)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play Policy](https://play.google.com/about/developer-content-policy/)

### 다음 단계
1. 위 체크리스트 항목들을 하나씩 완료
2. 내부 테스트 진행
3. 베타 테스트 진행 (TestFlight / Internal Testing)
4. 최종 배포

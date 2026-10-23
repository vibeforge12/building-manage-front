# Dev 환경 실행

Dev는 데이터베이스, 백엔드, Flutter 앱을 모두 로컬 자원으로 실행한다.
현재 staging과 prod의 설정 및 배포 방식은 변경하지 않는다.

## Android 준비 및 설치

Android 기기 한 대를 USB로 연결하고 디버깅을 허용한 뒤 프론트 프로젝트에서 실행한다.

```bash
make dev-android
```

이 명령은 다음 작업을 한 번에 수행한다.

1. 로컬 `building-manager-dev` DB 존재 여부 확인
2. DB 백업 및 서비스 신청 스키마 적용
3. 고정된 dev 테스트 계정 준비
4. 백엔드 빌드 및 `http://127.0.0.1:3002` 실행
5. 기기와 로컬 API 연결
6. `엄지 Dev` 앱 빌드, 설치 및 실행

Android와 iOS Dev 빌드는 실행별 `DEV_BUILD_REVISION`을 전달해 Dart/AOT 컴파일 입력을 갱신한다. Android에서 관찰한 이전 화면 잔존의 재발 방지 조치이며, 설치 후 실제 화면도 별도로 확인한다.
업데이트 설치 후 앱을 완전히 다시 열며 기존 로그인과 앱 데이터는 유지한다.

Dev FCM은 별도 Firebase 프로젝트 `building-management-dev-7ce57`을 사용한다.
백엔드 키는 Git에서 제외되는 `.dev/secrets/firebase-admin.json`에 보관한다.
Android 설정은 `config/firebase/dev/google-services.json`을 사용한다.
푸시 전송에는 인터넷이 필요하지만 DB와 API는 로컬로 유지한다.
iOS Dev App ID와 Firebase 개발용 APNs 인증 연결은 완료했다(2026-10-23).
APNs 키는 Sandbox / Topic Specific으로 Dev 앱 하나에만 제한되어 있다.
운영용 APNs 슬롯과 기존 staging 키는 변경하지 않았다.
2026-10-23 iPhone 13 Pro Max에 Dev 릴리스 빌드 설치 완료.
번들 ID·Firebase 프로젝트·개발용 APNs 서명과 코드서명 검증을 통과했다.
로그인·로컬 네트워크 권한·실제 푸시 수신은 사용자와 별도 확인이 필요하다.
빌드에는 외부 라이브러리 deprecated API 및 iOS 최소 버전 불일치 경고가 남아 있다.
기존 staging Firebase Admin 키나 Play Store 배포 키는 사용하지 않는다.

백엔드를 종료하려면 다음 명령을 실행한다.

```bash
make dev-stop
```

## iPhone 준비 및 설치

로컬 Dev API를 실행한 상태에서 맥과 iPhone을 같은 신뢰할 수 있는 LAN에 연결한다.
USB 연결·신뢰·개발자 모드와 Xcode 개발자 계정이 필요하다.

```bash
IOS_DEVICE_ID=<iPhone-UDID> make dev-ios
```

기본 API 주소는 맥의 en0 사설 IP와 3002 포트다. 필요하면 `DEV_API_HOST`를 지정한다.
별도 번들 `com.j2partners.buildingManageFront.dev`로 서명해 `엄지 Dev`를 설치한다.
기존 운영 앱과 소스 Firebase 설정은 보존한다. 처음 실행할 때 로컬 네트워크와 알림을 허용한다.
이 명령은 DB 초기화나 서버 재시작을 수행하지 않는다.

## 테스트 계정

기본 비밀번호는 `LocalTest!2026`이다. 입주민 A(`testa`), B(`test`), C(`testc`)의 비밀번호는 모두 `test1234`다(Dev 전용).

- 본사: `local_hq`
- 관리자: `MGR900001`, `MGR900002`
- 담당자: `STF900001`, `STF900002`
- 입주민: `testa`(기존 A와 동일한 사용자), `test`(기존 B와 동일한 사용자), `testc`(기존 C와 동일한 사용자, 다른 건물 접근 차단 확인용)

## 안전장치

### 서비스 사진 (2026-10-23)

- Dev는 백엔드 `.dev/uploads/life-services/<건물 ID>/`에 사진을 저장한다. 클라우드 S3에 업로드하지 않는다.
- DB에는 순서가 있는 `image_keys`만 보존하고, 조회 시 1시간 유효한 서명 주소를 생성한다. 별도 공개 정적 폴더는 없다.
- JPG/PNG/WebP, 최대 5장, 한 장 10MiB. 서비스 등록·수정 권한이 있는 관리자·담당자만 업로드할 수 있다.
- 수정에서 사진 제거는 서비스 첨부 연결만 해제한다. 저장소 파일을 즉시 삭제하지 않는다.
- 백엔드 최초 반영 전 DB 백업 후 `scripts/1.0.14-02-life-service-images.sql`을 적용한다. `make dev-android`의 스키마 준비에도 포함된다.
- staging/prod 코드 경로는 기존 비공개 S3 저장·서명 조회를 재사용한다. 이번 작업에서 해당 환경을 배포하거나 버킷/IAM을 변경하지 않았다.

- `NODE_ENV=dev` 백엔드는 로컬 호스트의 `building-manager-dev`만 허용한다.
- dev 앱은 별도 Android 패키지와 `엄지 Dev` 이름을 사용한다.
- dev HTTP 허용은 dev 앱 빌드에만 적용된다.
- dev FCM은 별도 테스트 Firebase 프로젝트에만 연결한다.
- 설치 실패 시 기존 앱을 자동 삭제하지 않는다.

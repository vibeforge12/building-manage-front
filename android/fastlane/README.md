fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android build

```sh
[bundle exec] fastlane android build
```

Flutter Android 릴리즈 빌드 (.aab 생성)

### android upload_internal

```sh
[bundle exec] fastlane android upload_internal
```

기존 AAB를 Google Play 내부 테스트 트랙에 업로드 (빌드 안 함)

### android upload_production

```sh
[bundle exec] fastlane android upload_production
```

기존 AAB를 Google Play 프로덕션 트랙에 업로드 (빌드 안 함)

### android internal

```sh
[bundle exec] fastlane android internal
```

빌드 + Google Play 내부 테스트 업로드 (iOS beta에 대응)

### android production

```sh
[bundle exec] fastlane android production
```

빌드 + Google Play 프로덕션 업로드 (스토어 공개 배포)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

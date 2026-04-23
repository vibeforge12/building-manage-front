fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### show_version

```sh
[bundle exec] fastlane show_version
```

현재 pubspec.yaml 버전 확인 (iOS/Android 공유 소스)

### bump_build

```sh
[bundle exec] fastlane bump_build
```

빌드 번호 +1 (pubspec.yaml) - iOS/Android 모두 반영

### bump_version

```sh
[bundle exec] fastlane bump_version
```

마케팅 버전 설정 (예: fastlane bump_version version:1.2.0)

### release_internal

```sh
[bundle exec] fastlane release_internal
```

iOS TestFlight + Android 내부 테스트 동시 배포 (빌드번호 자동 +1)

### release_production

```sh
[bundle exec] fastlane release_production
```

iOS App Store 심사 + Android 프로덕션(심사) 배포 (빌드번호 자동 +1)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

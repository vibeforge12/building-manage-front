fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Flutter iOS 릴리즈 빌드 (.ipa 생성)

### ios upload

```sh
[bundle exec] fastlane ios upload
```

기존 IPA를 TestFlight에 업로드 (빌드 안 함)

### ios beta

```sh
[bundle exec] fastlane ios beta
```

빌드 + TestFlight 업로드

### ios bump_build

```sh
[bundle exec] fastlane ios bump_build
```

빌드 번호 +1 (pubspec.yaml)

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

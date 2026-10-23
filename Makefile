.PHONY: quality dev-android dev-ios dev-stop

# 프론트·백엔드 정적 검사, 테스트, 실제 Android 빌드와 기기 성능 검사를 한 번에 실행한다.
quality:
	@./tool/quality_gate.sh

# 로컬 DB/API를 준비하고 연결된 Android에 dev 앱을 설치한다.
dev-android:
	@./tool/dev_android.sh

dev-ios:
	@bash ./tool/dev_ios.sh

# 이 명령이 실행한 dev 백엔드를 종료한다.
dev-stop:
	@./tool/dev_stop.sh

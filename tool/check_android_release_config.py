#!/usr/bin/env python3
"""Guard the minimum SDK required by this app's Play automatic protection."""
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
gradle = (root / "android/app/build.gradle.kts").read_text()
minimum = re.search(r"^\s*minSdk\s*=\s*(\d+)\s*$", gradle, re.M)
if not minimum:
    raise SystemExit("FAIL: Android minSdk의 명시적 설정을 찾지 못했습니다.")
if int(minimum.group(1)) < 24:
    raise SystemExit("FAIL: 활성화된 Play 자동 보호는 minSdk 24(Android 7.0) 이상이 필요합니다.")
print(f"PASS: Android minSdk {minimum.group(1)}; Play automatic protection minimum satisfied")

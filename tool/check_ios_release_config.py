#!/usr/bin/env python3
"""Check iOS deployment targets before building or uploading a release."""
import plistlib
import re
from pathlib import Path

root = Path(__file__).resolve().parent.parent
podfile = (root / "ios/Podfile").read_text()
platform = re.search(r"^platform\s+:ios,\s*['\"]([\d.]+)['\"]", podfile, re.M)
if not platform:
    raise SystemExit("FAIL: Podfile의 iOS platform을 찾지 못했습니다.")

def version(value):
    parts = tuple(int(part) for part in value.split("."))
    return parts + (0,) * (3 - len(parts))

minimum = platform.group(1)
if version(minimum) < (13, 0, 0):
    raise SystemExit("FAIL: App Store가 거절한 iOS 12 타깃을 다시 사용할 수 없습니다.")
framework = plistlib.loads((root / "ios/Flutter/AppFrameworkInfo.plist").read_bytes())
if version(framework["MinimumOSVersion"]) != version(minimum):
    raise SystemExit("FAIL: Flutter App.framework 최소 OS가 Podfile과 다릅니다.")
project = (root / "ios/Runner.xcodeproj/project.pbxproj").read_text()
targets = re.findall(r'IPHONEOS_DEPLOYMENT_TARGET\s*=\s*"?([\d.]+)"?;', project)
if not targets or any(version(target) < version(minimum) for target in targets):
    raise SystemExit("FAIL: Xcode 프로젝트의 iOS 최소 버전이 Podfile보다 낮습니다.")
print(f"PASS: iOS minimum {minimum}; Podfile / App.framework / Xcode configurations consistent")

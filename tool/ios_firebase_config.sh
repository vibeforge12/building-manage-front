#!/usr/bin/env bash
set -Eeuo pipefail
# Runs before Xcode signs the app; never changes the checked-in staging plist.
if [[ "${PRODUCT_BUNDLE_IDENTIFIER:-}" == com.j2partners.buildingManageFront.dev ]]; then
  CONFIG="$SRCROOT/../config/firebase/dev/GoogleService-Info.plist"
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :PROJECT_ID' "$CONFIG")" == building-management-dev-7ce57 ]]
  [[ "$(/usr/libexec/PlistBuddy -c 'Print :BUNDLE_ID' "$CONFIG")" == "$PRODUCT_BUNDLE_IDENTIFIER" ]]
  install -m 644 "$CONFIG" "$TARGET_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH/GoogleService-Info.plist"
fi

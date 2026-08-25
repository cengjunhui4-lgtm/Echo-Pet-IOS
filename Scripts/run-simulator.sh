#!/bin/bash
set -euo pipefail

PROJECT="EchoPet.xcodeproj"
SCHEME="EchoPet"
BUNDLE_ID="com.echopet.mvp"
DEVICE_NAME="${1:-iPhone 16}"
DERIVED_DATA=".derivedData"
APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/EchoPet.app"

cd "$(dirname "$0")/.."

echo "Looking for $DEVICE_NAME..."
DEVICE_ID="$(xcrun simctl list devices available | sed -n "s/^[[:space:]]*$DEVICE_NAME (\([A-F0-9-]*\)).*/\1/p" | head -n 1)"

if [ -z "$DEVICE_ID" ]; then
  echo "No available $DEVICE_NAME simulator was found."
  echo "Open Xcode > Settings > Platforms and install an iOS Simulator runtime."
  exit 1
fi

echo "Booting $DEVICE_NAME..."
xcrun simctl boot "$DEVICE_ID" 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus "$DEVICE_ID" -b

echo "Building Echo Pet..."
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "id=$DEVICE_ID" \
  -derivedDataPath "$DERIVED_DATA" \
  CODE_SIGNING_ALLOWED=NO \
  build

echo "Installing Echo Pet..."
xcrun simctl install "$DEVICE_ID" "$APP_PATH"

echo "Launching Echo Pet..."
xcrun simctl launch "$DEVICE_ID" "$BUNDLE_ID"

echo "Echo Pet is running on $DEVICE_NAME."

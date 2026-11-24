#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

echo "==> Generating Xcode project via XcodeGen..."
xcodegen generate

echo "==> Building MarkRead (Release)..."
xcodebuild \
  -project MarkRead.xcodeproj \
  -scheme MarkRead \
  -configuration Release \
  -derivedDataPath "$ROOT_DIR/.build/DerivedData" \
  build

APP_PATH="$ROOT_DIR/.build/DerivedData/Build/Products/Release/MarkRead.app"
echo "==> Build succeeded: $APP_PATH"

if [[ "${1:-}" == "--run" ]]; then
  echo "==> Launching MarkRead..."
  open "$APP_PATH"
fi

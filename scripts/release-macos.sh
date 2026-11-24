#!/usr/bin/env bash
# Build, sign (Developer ID + Hardened Runtime), notarize, staple, and package
# macOS releases for Apple Silicon (arm64) and Intel (x86_64).
#
# Usage:
#   ./scripts/release-macos.sh                # build arm64 + x86_64
#   ./scripts/release-macos.sh arm64          # build arm64 only
#   ./scripts/release-macos.sh x86_64         # build x86_64 only
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

APP_NAME="MarkRead"
EXT_NAME="MarkReadQuickLook"
NOTARY_PROFILE="${NOTARY_PROFILE:-quotabar-notary}"
VERSION="$(sed -n 's/.*MARKETING_VERSION:[[:space:]]*"\([^"]*\)".*/\1/p' project.yml | head -1)"

IDENTITY="-"
FOUND="$(security find-identity -v -p codesigning | sed -n 's/.*"\(Developer ID Application:[^"]*\)".*/\1/p' | head -1)"
if [[ -n "$FOUND" ]]; then
  IDENTITY="$FOUND"
fi

echo "==> MarkRead macOS Release v$VERSION"
echo "==> Signing identity: $IDENTITY"
echo "==> Notary profile:   $NOTARY_PROFILE"

xcodegen generate

notarize() {
  local target="$1"
  local log_file
  log_file="$(mktemp /tmp/markread-notary.XXXXXX.log)"
  for attempt in 1 2 3; do
    echo "==> Notarizing $(basename "$target") (attempt $attempt)..."
    if xcrun notarytool submit "$target" --keychain-profile "$NOTARY_PROFILE" --wait --timeout 20m 2>&1 | tee "$log_file" \
      && grep -q "status: Accepted" "$log_file"; then
      rm -f "$log_file"
      return 0
    fi
    sleep 10
  done
  rm -f "$log_file"
  echo "Error: Notarization failed for $target" >&2
  return 1
}

package_arch() {
  local arch="$1"
  local derived="$ROOT_DIR/.build/release-$arch"
  local built_app="$derived/Build/Products/Release/$APP_NAME.app"
  local stage_app_dir="$ROOT_DIR/.build/signed-$arch"
  local arch_app="$stage_app_dir/$APP_NAME.app"
  local ext_app="$arch_app/Contents/PlugIns/$EXT_NAME.appex"
  local zip="$ROOT_DIR/dist/$APP_NAME-$VERSION-$arch.zip"
  local dmg="$ROOT_DIR/dist/$APP_NAME-$VERSION-$arch.dmg"

  echo "==> Building $APP_NAME ($arch)..."
  rm -rf "$stage_app_dir"
  mkdir -p "$ROOT_DIR/dist" "$stage_app_dir"

  xcodebuild \
    -project "$ROOT_DIR/MarkRead.xcodeproj" \
    -scheme "$APP_NAME" \
    -configuration Release \
    -derivedDataPath "$derived" \
    ARCHS="$arch" \
    ONLY_ACTIVE_ARCH=NO \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO \
    build >/dev/null

  cp -R "$built_app" "$arch_app"

  local app_archs ext_archs
  app_archs="$(lipo -archs "$arch_app/Contents/MacOS/$APP_NAME")"
  ext_archs="$(lipo -archs "$ext_app/Contents/MacOS/$EXT_NAME")"
  if [[ "$app_archs" != "$arch" || "$ext_archs" != "$arch" ]]; then
    echo "Error: Arch mismatch! app=$app_archs ext=$ext_archs expected=$arch" >&2
    return 1
  fi

  # Sign inside-out: embedded Quick Look extension first, then host app
  if [[ "$IDENTITY" == "-" ]]; then
    codesign --force --entitlements "$ROOT_DIR/MarkReadQuickLook/MarkReadQuickLook.entitlements" --sign - "$ext_app"
    codesign --force --sign - "$arch_app"
    echo "==> Built $arch_app ($VERSION, $arch, ad-hoc signed)"
  else
    codesign --force --options runtime --timestamp \
      --entitlements "$ROOT_DIR/MarkReadQuickLook/MarkReadQuickLook.entitlements" \
      --sign "$IDENTITY" "$ext_app"
    codesign --force --options runtime --timestamp \
      --sign "$IDENTITY" "$arch_app"
    codesign --verify --deep --strict --verbose=2 "$arch_app"
    echo "==> Signed $arch_app ($VERSION, $arch) with $IDENTITY"
  fi

  rm -f "$zip" "$dmg"

  if [[ "$IDENTITY" != "-" ]]; then
    ditto -c -k --keepParent "$arch_app" "$zip"
    notarize "$zip"
    xcrun stapler staple "$arch_app"
    rm -f "$zip"
  fi
  ditto -c -k --keepParent "$arch_app" "$zip"

  # Create drag-to-Applications DMG
  local dmg_stage
  dmg_stage="$(mktemp -d)"
  cp -R "$arch_app" "$dmg_stage/"
  ln -s /Applications "$dmg_stage/Applications"
  hdiutil create -quiet -volname "$APP_NAME" -srcfolder "$dmg_stage" -fs HFS+ -format UDZO -ov "$dmg"
  rm -rf "$dmg_stage"

  if [[ "$IDENTITY" != "-" ]]; then
    codesign --force --timestamp --sign "$IDENTITY" "$dmg"
    notarize "$dmg"
    xcrun stapler staple "$dmg"
    spctl --assess --type open --context context:primary-signature -v "$dmg" || true
  fi
}

ARCHS=()
if [[ -n "${1:-}" ]]; then
  case "$1" in
    arm64|x86_64) ARCHS=("$1") ;;
    *) echo "Usage: $0 [arm64|x86_64]" >&2; exit 1 ;;
  esac
else
  ARCHS=(arm64 x86_64)
fi

FILES=()
for arch in "${ARCHS[@]}"; do
  package_arch "$arch"
  FILES+=("dist/$APP_NAME-$VERSION-$arch.zip" "dist/$APP_NAME-$VERSION-$arch.dmg")
done

echo "==> SHA-256 checksums:"
shasum -a 256 "${FILES[@]}"

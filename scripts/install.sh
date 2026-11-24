#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_APP="$ROOT_DIR/.build/DerivedData/Build/Products/Release/MarkRead.app"
DEST_APP="/Applications/MarkRead.app"
LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/Current/Frameworks/LaunchServices.framework/Versions/Current/Support/lsregister"

if [[ ! -d "$BUILD_APP" ]]; then
  echo "Error: $BUILD_APP not found. Run ./scripts/build.sh first." >&2
  exit 1
fi

echo "==> Installing MarkRead.app to $DEST_APP..."
rm -rf "$DEST_APP"
cp -R "$BUILD_APP" "$DEST_APP"

echo "==> Refreshing LaunchServices & Quick Look registration..."
"$LSREGISTER" -u "$BUILD_APP" 2>/dev/null || true
"$LSREGISTER" -f "$DEST_APP"
pluginkit -a "$DEST_APP/Contents/PlugIns/MarkReadQuickLook.appex" 2>/dev/null || true
pluginkit -e use -i com.markread.app.quicklook 2>/dev/null || true
qlmanage -r 2>/dev/null || true
qlmanage -r cache 2>/dev/null || true
echo "==> Quick Look extension status:"
pluginkit -m -v -i com.markread.app.quicklook || true

echo "==> Setting MarkRead.app as default handler for Markdown files..."
swift - "$DEST_APP" <<'EOF'
import AppKit
import CoreServices
import UniformTypeIdentifiers

let appPath = CommandLine.arguments[1]
let appURL = URL(fileURLWithPath: appPath)
let bundleID = "com.markread.app" as CFString

var utiSet = Set<String>([
    "net.daringfireball.markdown",
    "public.markdown"
])

for ext in ["md", "markdown", "mdown", "mkd", "mkdn"] {
    if let ut = UTType(filenameExtension: ext) {
        utiSet.insert(ut.identifier)
    }
}

let group = DispatchGroup()
for uti in utiSet.sorted() {
    let status = LSSetDefaultRoleHandlerForContentType(uti as CFString, .all, bundleID)
    print("  LSSetDefaultRoleHandler(\(uti)) -> status=\(status)")

    if let utType = UTType(uti) {
        group.enter()
        NSWorkspace.shared.setDefaultApplication(at: appURL, toOpen: utType) { error in
            if let error {
                print("  NSWorkspace.setDefaultApplication(\(uti)) note: \(error.localizedDescription)")
            }
            group.leave()
        }
    }
}

let deadline = Date().addingTimeInterval(5)
while group.wait(timeout: .now()) == .timedOut && Date() < deadline {
    RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
}

// Give LaunchServices a brief moment to flush the updated handler cache
Thread.sleep(forTimeInterval: 1.0)

print("==> Verification:")
for ext in ["md", "markdown", "mdown", "mkd"] {
    let ut = UTType(filenameExtension: ext)
    let defaultApp = ut.flatMap { NSWorkspace.shared.urlForApplication(toOpen: $0) }
    print("  .\(ext) (\(ut?.identifier ?? "unknown")) -> \(defaultApp?.path ?? "none")")
}
EOF

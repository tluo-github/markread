#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
rm -rf "$ROOT_DIR/windows/src/web"
mkdir -p "$ROOT_DIR/windows/src/web"
cp -R "$ROOT_DIR/shared/web/"* "$ROOT_DIR/windows/src/web/"
echo "Synced shared/web -> windows/src/web"

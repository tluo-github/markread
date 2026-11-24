<img src="docs/icon.png" width="96" alt="MarkRead icon">

# MarkRead

**A minimal, free & offline Markdown reader for macOS and Windows, inspired by Typora's typography aesthetics.**

English | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

MarkRead focuses purely on comfortable, distraction-free local Markdown reading — no account, no subscription, no network requests. Everything renders locally on your machine with crisp typography, offline Highlight.js syntax highlighting, and native OS integration.

## Features

- **Native & Lightweight**: Pure SwiftUI + WebKit on macOS (~2.5 MB) and Tauri v2 + WebView2 on Windows (~2.2 MB installer), with instant launch and zero network access
- **Finder Quick Look (macOS)**: Built-in `MarkReadQuickLook` extension — press Spacebar on any `.md` file in Finder for an instant formatted preview with syntax highlighting
- **5 Typora-Inspired Themes**: **GitHub (Auto Light/Dark)**, **GitHub Light**, **Night**, **Newsprint**, and **Vue** — with seamless window chrome and custom scrollbars
- **Offline Highlight.js Syntax Highlighting**: 35+ languages bundled offline with language badge and one-click code copy
- **Rich Markdown Rendering**: GFM tables, custom checkboxes for task lists, strikethrough, GitHub/Obsidian Callout alerts (`NOTE` / `TIP` / `IMPORTANT` / `WARNING` / `CAUTION`), `==text highlight==`, YAML Front Matter toggle, local relative images with click-to-zoom lightbox, and relative `.md` link navigation
- **Reading Productivity**: Collapsible Table of Contents sidebar with live scroll sync and word count / reading time stats, in-document find with match navigation, and live file auto-reload that preserves scroll position when edited externally
- **Export**: Export cleanly to **PDF** or self-contained **HTML**
- **5 Languages**: English, 简体中文, 繁體中文, 日本語, and 한국어 — follows your system language or switch live anytime

## Install

### macOS (Homebrew — Recommended)

Signed with Apple Developer ID and notarized by Apple:

```bash
brew tap tluo-github/markread https://github.com/tluo-github/markread
brew install --cask markread
```

Upgrade with `brew upgrade --cask markread`, remove with `brew uninstall --cask markread`.

### Direct Download (macOS & Windows)

Download from [GitHub Releases](https://github.com/tluo-github/markread/releases/latest):

- **macOS (Apple Silicon)**: `MarkRead-<version>-arm64.dmg`
- **macOS (Intel)**: `MarkRead-<version>-x86_64.dmg`
- **Windows Installer** (auto-registers `.md` file association, no admin required): `MarkRead_<version>_x64-setup.exe` or `.msi`
- **Windows Portable** (single-file, no installation): `MarkRead-portable-x64.exe`

## Shortcuts

| Action | macOS | Windows |
| :--- | :--- | :--- |
| Open Markdown file | `⌘O` | `Ctrl+O` |
| Toggle Outline (TOC) | `⇧⌘O` | `Ctrl+Shift+O` |
| Find in document | `⌘F` / `⌘G` / `⇧⌘G` | `Ctrl+F` / `F3` / `Shift+F3` |
| Show / Hide Front Matter | `⇧⌘M` | `Ctrl+Shift+M` |
| Zoom In / Out / Reset | `⌘+` / `⌘-` / `⌘0` | `Ctrl++` / `Ctrl+-` / `Ctrl+0` |
| Reload file | `⌘R` | `Ctrl+R` |
| Reveal in Finder / Explorer | `⇧⌘R` | `Ctrl+Shift+R` |
| Export HTML | `⇧⌘E` | `Ctrl+Shift+E` |
| Export PDF / Print | `⇧⌘P` | `Ctrl+P` |

## Architecture

- `shared/web/`: Single-source offline rendering engine (`markdown-it`, `Highlight.js`, `themes.css`, `renderer.js`) shared 100% by macOS and Windows
- `MarkRead/` & `MarkReadQuickLook/`: Native macOS SwiftUI app + Finder Quick Look extension
- `windows/`: Lightweight Windows Tauri v2 (Rust + WebView2) app
- `.github/workflows/build-windows.yml`: Automated Windows NSIS / MSI / Portable `.exe` builds via GitHub Actions

## Build from Source

### macOS

Requires Xcode and [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
./scripts/build.sh --run     # Build & launch locally
./scripts/install.sh         # Install to /Applications, enable Quick Look & set default .md app
./scripts/release-macos.sh   # Build, sign, notarize & package arm64 + x86_64 DMG/ZIP
```

### Windows

Requires Rust stable, Node.js, and `@tauri-apps/cli@2`:

```bash
./scripts/sync-windows-web.sh
cd windows && tauri build
```

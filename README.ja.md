<img src="docs/icon.png" width="96" alt="MarkRead アイコン">

# MarkRead

**Typora のタイポグラフィ美学にインスパイアされた、無料・完全オフラインの macOS / Windows 向けミニマル Markdown リーダー。**

[English](README.md) | [简体中文](README.zh-CN.md) | [繁體中文](README.zh-TW.md) | 日本語 | [한국어](README.ko.md)

MarkRead は、ローカルの Markdown ドキュメントを快適に読むことだけに特化したリーダーです。アカウント登録不要・サブスクリプション不要・ネットワーク通信ゼロで、美しい組版、オフライン Highlight.js シンタックスハイライト、OS ネイティブな操作性を提供します。

## 主な機能

- **ネイティブ＆超軽量**：macOS は純粋な SwiftUI + WebKit（約 2.5 MB）、Windows は Tauri v2 + WebView2（インストーラー約 2.2 MB）。高速起動・完全オフライン動作
- **Finder クイックルック対応（macOS）**：`MarkReadQuickLook` 拡張を内蔵。Finder で `.md` ファイルを選んでスペースキーを押すだけで、整形＆ハイライト済みプレビューを瞬時に表示
- **5 種類の Typora 風テーマ**：**GitHub（自動ライト/ダーク）**、**GitHub Light**、**Night**、**Newsprint**、**Vue**。ウィンドウタイトルバーと自然に調和
- **オフライン Highlight.js シンタックスハイライト**：35 以上の言語をオフライン内蔵。言語ラベル表示＆ワンクリックコピーに対応
- **豊富な Markdown 表現**：GFM テーブル、チェックボックス付きタスクリスト、打ち消し線、GitHub / Obsidian 形式の Callout カード（`NOTE` / `TIP` / `IMPORTANT` / `WARNING` / `CAUTION`）、`==ハイライト==`、YAML Front Matter の表示切替、相対パス画像（クリックでライトボックス拡大表示）、相対 `.md` リンク遷移
- **快適な読書サポート**：スクロール連動の折りたたみ式アウトライン（TOC）・語数/読了目安表示、ドキュメント内検索、外部エディタでの保存を検知してスクロール位置を保ったまま自動リロード
- **書き出し機能**：**PDF** および単一ファイル **HTML** への書き出しに対応
- **5 言語対応**：日本語・English・简体中文・繁體中文・한국어。システム言語に追従、またはアプリ内から再起動なしで即時切替可能

## インストール

### macOS（Homebrew 推奨）

Apple Developer ID で署名・Apple 公証済みのため、インストール後すぐに起動できます：

```bash
brew tap tluo-github/markread https://github.com/tluo-github/markread
brew install --cask markread
```

アップデート：`brew upgrade --cask markread` · アンインストール：`brew uninstall --cask markread`

### 直接ダウンロード（macOS & Windows）

[GitHub Releases](https://github.com/tluo-github/markread/releases/latest) からダウンロード：

- **macOS (Apple Silicon)**：`MarkRead-<version>-arm64.dmg`
- **macOS (Intel)**：`MarkRead-<version>-x86_64.dmg`
- **Windows インストーラー**（`.md` 関連付け自動登録・管理者権限不要）：`MarkRead_<version>_x64-setup.exe` または `.msi`
- **Windows ポータブル版**（インストール不要の単一 EXE）：`MarkRead-portable-x64.exe`

## ショートカット

| 操作 | macOS | Windows |
| :--- | :--- | :--- |
| Markdown ファイルを開く | `⌘O` | `Ctrl+O` |
| アウトライン（TOC）切替 | `⇧⌘O` | `Ctrl+Shift+O` |
| ドキュメント内検索 / 次 / 前 | `⌘F` / `⌘G` / `⇧⌘G` | `Ctrl+F` / `F3` / `Shift+F3` |
| Front Matter 表示切替 | `⇧⌘M` | `Ctrl+Shift+M` |
| 拡大 / 縮小 / リセット | `⌘+` / `⌘-` / `⌘0` | `Ctrl++` / `Ctrl+-` / `Ctrl+0` |
| ファイルを再読み込み | `⌘R` | `Ctrl+R` |
| Finder / エクスプローラーで表示 | `⇧⌘R` | `Ctrl+Shift+R` |
| HTML 書き出し | `⇧⌘E` | `Ctrl+Shift+E` |
| PDF 書き出し / 印刷 | `⇧⌘P` | `Ctrl+P` |

## アーキテクチャ

- `shared/web/`：macOS と Windows で 100% 共有されるオフライン描画エンジン（`markdown-it`、`Highlight.js`、`themes.css`、`renderer.js`）
- `MarkRead/` & `MarkReadQuickLook/`：ネイティブ macOS SwiftUI アプリ＆Finder Quick Look 拡張
- `windows/`：Tauri v2（Rust + WebView2）ベースの軽量 Windows アプリ
- `.github/workflows/build-windows.yml`：GitHub Actions による Windows NSIS / MSI / ポータブル EXE 自動ビルド

## ソースからビルド

### macOS

Xcode と [XcodeGen](https://github.com/yonaskolb/XcodeGen) が必要です：

```bash
./scripts/build.sh --run     # ローカルビルド＆起動
./scripts/install.sh         # /Applications へインストール・Quick Look 有効化・.md 既定アプリ設定
./scripts/release-macos.sh   # arm64 + x86_64 の署名・公証・DMG/ZIP 作成
```

### Windows

Rust stable、Node.js、`@tauri-apps/cli@2` が必要です：

```bash
./scripts/sync-windows-web.sh
cd windows && tauri build
```

<img src="docs/icon.png" width="96" alt="MarkRead 圖示">

# MarkRead

**免費、離線、無需註冊的 macOS / Windows 極簡本機 Markdown 閱讀器，致敬 Typora 排版美學。**

[English](README.md) | [简体中文](README.zh-CN.md) | 繁體中文 | [日本語](README.ja.md) | [한국어](README.ko.md)

MarkRead 專注於純粹舒適的本機 Markdown 閱讀體驗——無帳號、無訂閱、零網路請求。所有內容皆在你的電腦本機即時算繪，結合精緻的中英文排版、離線 Highlight.js 語法突顯與原生桌面整合。

## 核心特色

- **原生極致輕量**：macOS 採用純 SwiftUI + WebKit（僅 ~2.5 MB），Windows 採用 Tauri v2 + 系統 WebView2（安裝檔僅 ~2.2 MB），秒速啟動、零網路相依
- **Finder 空白鍵預覽（macOS）**：內建原生 `MarkReadQuickLook` 延伸功能，在 Finder 選取任意 `.md` 檔案按空白鍵即可即時預覽完整排版與程式碼高亮
- **5 套 Typora 風格排版主題**：**GitHub（跟隨系統淺/深色）**、**GitHub Light**、**Night**、**Newsprint**、**Vue**，標題列與頁面無縫融合
- **離線 Highlight.js 語法突顯**：內建 35+ 常用程式語言離線高亮、語言標籤與一鍵複製程式碼
- **完整 Markdown 算繪**：GFM 表格、自訂核取方塊待辦清單、刪除線、GitHub / Obsidian 風格 Callout 提示卡片（`NOTE` / `TIP` / `IMPORTANT` / `WARNING` / `CAUTION`）、`==螢光筆標記==`、YAML Front Matter 顯示/隱藏、本機相對路徑圖片（支援點擊燈箱檢視大圖）與相對 `.md` 連結跳轉
- **高效閱讀體驗**：可摺疊目錄大綱（TOC）隨捲動同步高亮目前章節、字數與預估閱讀時間統計、文件內搜尋高亮跳轉、外部編輯器存檔自動熱重整並保留捲動位置
- **文件匯出**：支援直接匯出 **PDF** 與樣式內嵌的獨立 **HTML**
- **五語介面**：支援繁體中文、简体中文、English、日本語、한국어，預設跟隨系統並可隨時即時切換無需重啟

## 安裝與下載

### macOS（Homebrew，推薦）

已通過 Apple Developer ID 簽章與 Apple 公證，安裝後即可直接雙擊開啟：

```bash
brew tap tluo-github/markread https://github.com/tluo-github/markread
brew install --cask markread
```

更新：`brew upgrade --cask markread` · 解除安裝：`brew uninstall --cask markread`

### 直接下載安裝檔（macOS & Windows）

前往 [GitHub Releases](https://github.com/tluo-github/markread/releases/latest) 下載：

- **macOS (Apple Silicon)**：`MarkRead-<version>-arm64.dmg`
- **macOS (Intel)**：`MarkRead-<version>-x86_64.dmg`
- **Windows 安裝版**（自動註冊 `.md` 檔案關聯，無需系統管理員權限）：`MarkRead_<version>_x64-setup.exe` 或 `.msi`
- **Windows 免安裝可攜版**（單一執行檔）：`MarkRead-portable-x64.exe`

## 快捷鍵

| 功能 | macOS | Windows |
| :--- | :--- | :--- |
| 開啟 Markdown 檔案 | `⌘O` | `Ctrl+O` |
| 顯示/隱藏目錄大綱 | `⇧⌘O` | `Ctrl+Shift+O` |
| 文件內尋找 / 下一個 / 上一個 | `⌘F` / `⌘G` / `⇧⌘G` | `Ctrl+F` / `F3` / `Shift+F3` |
| 顯示/隱藏 Front Matter | `⇧⌘M` | `Ctrl+Shift+M` |
| 放大 / 縮小 / 實際大小 | `⌘+` / `⌘-` / `⌘0` | `Ctrl++` / `Ctrl+-` / `Ctrl+0` |
| 重新載入檔案 | `⌘R` | `Ctrl+R` |
| 在 Finder / 檔案總管中顯示 | `⇧⌘R` | `Ctrl+Shift+R` |
| 匯出獨立 HTML | `⇧⌘E` | `Ctrl+Shift+E` |
| 匯出 PDF / 列印 | `⇧⌘P` | `Ctrl+P` |

## 跨平台目錄結構

- `shared/web/`：macOS 與 Windows 100% 共用的離線排版與語法突顯引擎（`markdown-it`、`Highlight.js`、`themes.css`、`renderer.js`）
- `MarkRead/` & `MarkReadQuickLook/`：原生 macOS SwiftUI 應用程式與 Finder Quick Look 延伸功能
- `windows/`：基於 Tauri v2（Rust + WebView2）的輕量 Windows 用戶端
- `.github/workflows/build-windows.yml`：透過 GitHub Actions 自動雲端建置 Windows NSIS / MSI / 可攜版 `.exe`

## 從原始碼建置

### macOS

需安裝 Xcode 與 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```bash
./scripts/build.sh --run     # 本機建置並啟動
./scripts/install.sh         # 安裝至 /Applications、啟用 Quick Look 並設為 .md 預設程式
./scripts/release-macos.sh   # 建置、Developer ID 簽章、公證並打包 arm64 + x86_64 DMG/ZIP
```

### Windows

需安裝 Rust stable、Node.js 與 `@tauri-apps/cli@2`：

```bash
./scripts/sync-windows-web.sh
cd windows && tauri build
```

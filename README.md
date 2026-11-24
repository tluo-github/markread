# MarkRead

**MarkRead** 是一个免费、完全离线、无需注册的 macOS 原生 Markdown 本地阅读器，致敬 Typora 的排版美学，专注于纯粹舒适的文档阅读体验。

## 特性

- **原生 macOS 体验**：基于 SwiftUI + WKWebView 构建，启动快、体积小、零网络请求
- **Finder 空格预览（Quick Look）**：内置原生 `MarkReadQuickLook` 扩展，在访达选中任意 `.md` 按空格即可秒开高亮排版预览（支持自动跟随系统深浅色）
- **Typora 风格排版主题**：内置 **GitHub (Auto)**、**GitHub Light**、**Night**、**Newsprint**、**Vue** 五套主题
- **离线语法高亮**：内置 `Highlight.js`（35+ 常用编程语言离线支持）与一键复制代码
- **完整 GFM 渲染**：支持表格、任务列表、删除线、Callout 提示卡片、`==荧光高亮==`、本地相对路径图片（含点击大图灯箱）与文档间相对链接跳转
- **YAML Front Matter**：支持快捷键 `⌘⇧M` 隐藏或优雅展示文档元信息
- **目录大纲（TOC）**：可折叠原生侧边栏（`⌘⇧O`），滚动自动同步当前章节并统计字数与阅读时间
- **文内搜索**：`⌘F` 高亮匹配项并支持 `⌘G` / `⇧⌘G` 快速跳转
- **文件变动热刷新**：外部编辑器修改 `.md` 后自动刷新并保持当前滚动位置
- **导出 PDF & HTML**：支持从菜单栏直接导出 PDF（`⌘⇧P`）与独立 HTML（`⌘⇧E`）

## 安装与下载

### macOS（Homebrew，推荐）

已通过 Apple Developer ID 签名与公证，安装后直接双击打开：

```bash
brew tap tluo-github/markread https://github.com/tluo-github/markread
brew install --cask markread
```

升级：`brew upgrade --cask markread` · 卸载：`brew uninstall --cask markread`

### 直接下载安装包（macOS & Windows）

前往 [GitHub Releases](https://github.com/tluo-github/markread/releases/latest) 下载：

- **macOS (Apple Silicon)**：`MarkRead-0.1.0-arm64.dmg`
- **macOS (Intel)**：`MarkRead-0.1.0-x86_64.dmg`
- **Windows 安装版（自动关联 `.md`）**：`MarkRead_0.1.0_x64-setup.exe` 或 `.msi`
- **Windows 免安装便携版**：`MarkRead-portable-x64.exe`

## 跨平台目录结构

- `shared/web/`：macOS 与 Windows 100% 共享的离线排版与语法高亮引擎（`markdown-it` + `Highlight.js` + 5 套 Typora 风格主题）
- `MarkRead/` & `MarkReadQuickLook/`：原生 macOS SwiftUI 应用与 Finder 空格 Quick Look 预览扩展
- `windows/`：基于 Tauri v2（Rust + 系统 WebView2）的轻量 Windows 客户端
- `.github/workflows/build-windows.yml`：GitHub Actions 自动云编译 Windows 安装包与便携版 `.exe`

## macOS 构建与安装

```bash
chmod +x scripts/build.sh scripts/install.sh
./scripts/build.sh --run

# 安装到 /Applications、启用 Finder Quick Look 并设为 .md 默认应用
./scripts/install.sh
```

或者生成 Xcode 工程后在 Xcode 中打开：

```bash
xcodegen generate
open MarkRead.xcodeproj
```

## Windows 云编译（GitHub Actions）

将仓库推送到 GitHub 后，`.github/workflows/build-windows.yml` 会在 `windows-latest` 上自动产出三份文件：

1. **NSIS 安装包**（`MarkRead_0.1.0_x64-setup.exe`，安装时自动注册 `.md` 文件关联，无需管理员权限）
2. **MSI 安装包**（`MarkRead_0.1.0_x64_en-US.msi`）
3. **免安装便携版**（`MarkRead-portable-x64.exe`）

- 推送到 `main` 分支或在 GitHub **Actions** 页面手动点击 **Run workflow**，即可在构建产物 **Artifacts** 中下载；
- 推送版本标签（如 `git tag v0.1.0 && git push origin v0.1.0`），会自动创建 **GitHub Release** 并附上全部安装包。

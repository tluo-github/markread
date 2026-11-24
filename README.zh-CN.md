<img src="docs/icon.png" width="96" alt="MarkRead 图标">

# MarkRead

**免费、离线、无需注册的 macOS / Windows 极简本地 Markdown 阅读器，致敬 Typora 排版美学。**

[English](README.md) | 简体中文 | [繁體中文](README.zh-TW.md) | [日本語](README.ja.md) | [한국어](README.ko.md)

MarkRead 专注于纯粹舒适的本地 Markdown 阅读体验——无账号、无订阅、零网络请求。所有内容均在你的电脑本地即时渲染，兼具优雅的中英文排版、离线 Highlight.js 语法高亮与原生桌面集成。

## 核心特性

- **原生极致轻量**：macOS 端采用纯 SwiftUI + WebKit（仅 ~2.5 MB），Windows 端采用 Tauri v2 + 系统 WebView2（安装包仅 ~2.2 MB），启动秒开、零网络依赖
- **Finder 空格预览（macOS）**：内置原生 `MarkReadQuickLook` 扩展，在访达中选中任意 `.md` 文件按空格键即可毫秒级预览完整排版与代码高亮
- **5 套 Typora 风格排版主题**：**GitHub（跟随系统浅/深色）**、**GitHub Light**、**Night**、**Newsprint**、**Vue**，标题栏与正文无缝融合
- **离线 Highlight.js 语法高亮**：内置 35+ 常用编程语言离线高亮、语言标签与一键复制代码
- **完整 Markdown 渲染**：GFM 表格、自定义复选框任务列表、删除线、GitHub / Obsidian 风格 Callout 提示卡片（`NOTE` / `TIP` / `IMPORTANT` / `WARNING` / `CAUTION`）、`==荧光笔高亮==`、YAML Front Matter 隐藏/展示、本地相对路径图片（含点击毛玻璃灯箱查看大图）以及相对 `.md` 链接文档间跳转
- **高效阅读体验**：可折叠目录大纲（TOC）滚动实时高亮当前章节、字数与预计阅读时间统计、文内搜索高亮跳转、外部编辑器保存自动热刷新并保持滚动位置
- **文档导出**：支持直接导出 **PDF** 与样式内嵌的独立 **HTML**
- **五语界面**：支持简体中文、繁體中文、English、日本語、한국어，默认跟随系统并支持随时无重启实时切换

## 安装与下载

### macOS（Homebrew，推荐）

已通过 Apple Developer ID 签名与 Apple 公证，安装后可直接双击运行：

```bash
brew tap tluo-github/markread https://github.com/tluo-github/markread
brew install --cask markread
```

升级：`brew upgrade --cask markread` · 卸载：`brew uninstall --cask markread`

### 直接下载安装包（macOS & Windows）

前往 [GitHub Releases](https://github.com/tluo-github/markread/releases/latest) 下载：

- **macOS (Apple Silicon)**：`MarkRead-<version>-arm64.dmg`
- **macOS (Intel)**：`MarkRead-<version>-x86_64.dmg`
- **Windows 安装版**（自动注册 `.md` 文件关联，无需管理员权限）：`MarkRead_<version>_x64-setup.exe` 或 `.msi`
- **Windows 免安装便携版**（单文件直接运行）：`MarkRead-portable-x64.exe`

## 快捷键

| 操作 | macOS | Windows |
| :--- | :--- | :--- |
| 打开 Markdown 文件 | `⌘O` | `Ctrl+O` |
| 显示/隐藏目录大纲 | `⇧⌘O` | `Ctrl+Shift+O` |
| 文内查找 / 下一个 / 上一个 | `⌘F` / `⌘G` / `⇧⌘G` | `Ctrl+F` / `F3` / `Shift+F3` |
| 显示/隐藏 Front Matter | `⇧⌘M` | `Ctrl+Shift+M` |
| 放大 / 缩小 / 实际大小 | `⌘+` / `⌘-` / `⌘0` | `Ctrl++` / `Ctrl+-` / `Ctrl+0` |
| 重新加载文件 | `⌘R` | `Ctrl+R` |
| 在访达 / 资源管理器中显示 | `⇧⌘R` | `Ctrl+Shift+R` |
| 导出独立 HTML | `⇧⌘E` | `Ctrl+Shift+E` |
| 导出 PDF / 打印 | `⇧⌘P` | `Ctrl+P` |

## 跨平台目录结构

- `shared/web/`：macOS 与 Windows 100% 共享的离线排版与语法高亮引擎（`markdown-it`、`Highlight.js`、`themes.css`、`renderer.js`）
- `MarkRead/` & `MarkReadQuickLook/`：原生 macOS SwiftUI 应用与 Finder 空格 Quick Look 扩展
- `windows/`：基于 Tauri v2（Rust + WebView2）的轻量 Windows 客户端
- `.github/workflows/build-windows.yml`：GitHub Actions 自动云编译 Windows NSIS / MSI / 便携版 `.exe`

## 从源码构建

### macOS

需安装 Xcode 与 [XcodeGen](https://github.com/yonaskolb/XcodeGen)：

```bash
./scripts/build.sh --run     # 本地编译并运行
./scripts/install.sh         # 安装到 /Applications、启用 Quick Look 并设为 .md 默认应用
./scripts/release-macos.sh   # 编译、Developer ID 签名、公证并打包 arm64 + x86_64 DMG/ZIP
```

### Windows

需安装 Rust stable、Node.js 与 `@tauri-apps/cli@2`：

```bash
./scripts/sync-windows-web.sh
cd windows && tauri build
```

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case system = "system"
    case en = "en"
    case zhHans = "zh-CN"
    case zhHant = "zh-TW"
    case ja = "ja"
    case ko = "ko"

    var id: String { rawValue }

    var nativeName: String {
        switch self {
        case .system: return L10n.followSystem(for: Self.resolveSystem())
        case .en: return "English"
        case .zhHans: return "简体中文"
        case .zhHant: return "繁體中文"
        case .ja: return "日本語"
        case .ko: return "한국어"
        }
    }

    var resolved: AppLanguage {
        self == .system ? Self.resolveSystem() : self
    }

    static func resolveSystem() -> AppLanguage {
        for pref in Locale.preferredLanguages {
            let lower = pref.lowercased()
            if lower.hasPrefix("zh-hant") || lower.hasPrefix("zh-tw") || lower.hasPrefix("zh-hk") || lower.hasPrefix("zh-mo") {
                return .zhHant
            }
            if lower.hasPrefix("zh") {
                return .zhHans
            }
            if lower.hasPrefix("ja") {
                return .ja
            }
            if lower.hasPrefix("ko") {
                return .ko
            }
            if lower.hasPrefix("en") {
                return .en
            }
        }
        return .en
    }
}

struct L10n {
    let lang: AppLanguage

    init(_ language: AppLanguage) {
        self.lang = language.resolved
    }

    static func followSystem(for resolved: AppLanguage) -> String {
        switch resolved {
        case .zhHans: return "跟随系统"
        case .zhHant: return "跟隨系統"
        case .ja: return "システムに従う"
        case .ko: return "시스템 설정 따르기"
        default: return "Follow System"
        }
    }

    private func t(_ en: String, _ zhCN: String, _ zhTW: String, _ ja: String, _ ko: String) -> String {
        switch lang {
        case .zhHans: return zhCN
        case .zhHant: return zhTW
        case .ja: return ja
        case .ko: return ko
        default: return en
        }
    }

    // Menus & Commands
    var openMenu: String { t("Open…", "打开…", "開啟…", "開く…", "열기…") }
    var openShowcaseMenu: String { t("Open Showcase Document", "打开示例文档", "開啟範例文件", "サンプルドキュメントを開く", "샘플 문서 열기") }
    var reloadFile: String { t("Reload File", "重新加载文件", "重新載入檔案", "ファイルを再読み込み", "파일 다시 불러오기") }
    var revealInFinder: String { t("Reveal in Finder", "在访达中显示", "在 Finder 中顯示", "Finder で表示", "Finder에서 보기") }
    var exportPDF: String { t("Export as PDF…", "导出为 PDF…", "匯出為 PDF…", "PDF として書き出す…", "PDF로 내보내기…") }
    var exportHTML: String { t("Export as HTML…", "导出为 HTML…", "匯出為 HTML…", "HTML として書き出す…", "HTML로 내보내기…") }

    var findMenu: String { t("Find…", "查找…", "尋找…", "検索…", "찾기…") }
    var findNext: String { t("Find Next", "查找下一个", "尋找下一個", "次を検索", "다음 찾기") }
    var findPrevious: String { t("Find Previous", "查找上一个", "尋找上一個", "前を検索", "이전 찾기") }

    var viewMenu: String { t("View", "显示", "顯示方式", "表示", "보기") }
    var toggleOutline: String { t("Toggle Outline", "显示/隐藏大纲", "顯示/隱藏大綱", "アウトラインを切り替え", "개요 토글") }
    var showFrontMatter: String { t("Show Front Matter", "显示 Front Matter", "顯示 Front Matter", "Front Matter を表示", "Front Matter 표시") }
    var hideFrontMatter: String { t("Hide Front Matter", "隐藏 Front Matter", "隱藏 Front Matter", "Front Matter を隠す", "Front Matter 숨기기") }
    var themeMenu: String { t("Theme", "主题", "主題", "テーマ", "테마") }
    var pageWidthMenu: String { t("Page Width", "版心宽度", "頁面寬度", "ページ幅", "페이지 너비") }
    var languageMenu: String { t("Language", "语言", "語言", "言語", "언어") }
    var zoomIn: String { t("Zoom In", "放大", "放大", "拡大", "확대") }
    var zoomOut: String { t("Zoom Out", "缩小", "縮小", "縮小", "축소") }
    var actualSize: String { t("Actual Size", "实际大小", "實際大小", "実際のサイズ", "실제 크기") }

    // Theme & Width names
    func themeName(_ theme: ReaderTheme) -> String {
        switch theme {
        case .auto: return t("GitHub (Auto)", "GitHub（跟随系统）", "GitHub（跟隨系統）", "GitHub（自動）", "GitHub (자동)")
        case .githubLight: return "GitHub Light"
        case .night: return "Night"
        case .newsprint: return "Newsprint"
        case .vue: return "Vue"
        }
    }

    func pageWidthName(_ width: PageWidth) -> String {
        switch width {
        case .narrow: return t("Narrow (720px)", "窄版 (720px)", "窄版 (720px)", "狭い (720px)", "좁게 (720px)")
        case .standard: return t("Standard (860px)", "标准 (860px)", "標準 (860px)", "標準 (860px)", "표준 (860px)")
        case .wide: return t("Wide (1080px)", "宽版 (1080px)", "寬版 (1080px)", "広い (1080px)", "넓게 (1080px)")
        case .full: return t("Full Width", "铺满窗口", "填滿視窗", "全幅", "전체 너비")
        }
    }

    // Welcome View
    var welcomeSubtitle: String {
        t(
            "Minimal, free & offline Markdown reader for macOS",
            "免费、离线、极简的 macOS Markdown 阅读器",
            "免費、離線、極簡的 macOS Markdown 閱讀器",
            "無料でオフライン動作するミニマルな macOS 用 Markdown リーダー",
            "무료 · 오프라인 미니멀 macOS Markdown 리더"
        )
    }
    var welcomeOpenButton: String { t("Open Markdown File…", "打开 Markdown 文件…", "開啟 Markdown 檔案…", "Markdown ファイルを開く…", "Markdown 파일 열기…") }
    var welcomeSampleButton: String { t("Open Showcase", "打开示例文档", "開啟範例文件", "サンプルを開く", "샘플 열기") }
    var welcomeHint: String {
        t(
            "Or drag & drop any .md file onto this window  ·  ⌘O to open",
            "或直接拖入任意 .md 文件到此窗口  ·  按 ⌘O 打开",
            "或直接拖曳任意 .md 檔案至此視窗  ·  按 ⌘O 開啟",
            "または .md ファイルをこのウィンドウへドラッグ＆ドロップ  ·  ⌘O で開く",
            "또는 .md 파일을 이 창으로 드래그 앤 드롭  ·  ⌘O로 열기"
        )
    }

    // Sidebar & Find & Tooltips
    var outlineTitle: String { t("Outline", "目录大纲", "目錄大綱", "アウトライン", "개요") }
    var noHeadings: String { t("No Headings", "暂无标题", "尚無標題", "見出しなし", "제목 없음") }
    func wordsCount(_ count: Int) -> String {
        switch lang {
        case .zhHans: return "\(count) 字"
        case .zhHant: return "\(count) 字"
        case .ja: return "\(count) 語"
        case .ko: return "\(count) 단어"
        default: return "\(count) words"
        }
    }
    func readingMinutes(_ minutes: Int) -> String {
        switch lang {
        case .zhHans: return "约 \(minutes) 分钟"
        case .zhHant: return "約 \(minutes) 分鐘"
        case .ja: return "約 \(minutes) 分"
        case .ko: return "약 \(minutes)분"
        default: return "~\(minutes) min read"
        }
    }

    var findPlaceholder: String { t("Find in document…", "在文档中查找…", "在文件中尋找…", "ドキュメント内を検索…", "문서에서 찾기…") }
    var prevMatchTip: String { t("Previous Match (⇧⌘G)", "上一个匹配项 (⇧⌘G)", "上一個相符項目 (⇧⌘G)", "前の候補 (⇧⌘G)", "이전 항목 (⇧⌘G)") }
    var nextMatchTip: String { t("Next Match (⌘G)", "下一个匹配项 (⌘G)", "下一個相符項目 (⌘G)", "次の候補 (⌘G)", "다음 항목 (⌘G)") }
    var closeFindTip: String { t("Close Find (Esc)", "关闭查找 (Esc)", "關閉尋找 (Esc)", "検索を閉じる (Esc)", "찾기 닫기 (Esc)") }

    var toggleOutlineTip: String { t("Toggle Outline (⇧⌘O)", "显示/隐藏大纲 (⇧⌘O)", "顯示/隱藏大綱 (⇧⌘O)", "アウトラインを切り替え (⇧⌘O)", "개요 토글 (⇧⌘O)") }
    var findTip: String { t("Find in Document (⌘F)", "在文档中查找 (⌘F)", "在文件中尋找 (⌘F)", "ドキュメント内を検索 (⌘F)", "문서에서 찾기 (⌘F)") }
    var appearanceTip: String { t("Appearance & Themes", "外观与主题", "外觀與主題", "外観とテーマ", "화면 및 테마") }
    var dropPrompt: String { t("Drop to read Markdown", "松开即可阅读 Markdown", "放開即可閱讀 Markdown", "ドロップして Markdown を開く", "놓아서 Markdown 읽기") }
    var openErrorTitle: String { t("Unable to Open File", "无法打开文件", "無法開啟檔案", "ファイルを開けません", "파일을 열 수 없음") }
    var okButton: String { t("OK", "好", "好", "OK", "확인") }
}

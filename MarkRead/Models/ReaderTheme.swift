import AppKit
import SwiftUI

enum ReaderTheme: String, CaseIterable, Identifiable {
    case auto = "github-auto"
    case githubLight = "github-light"
    case night = "night"
    case newsprint = "newsprint"
    case vue = "vue"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .auto: return "GitHub (Auto)"
        case .githubLight: return "GitHub Light"
        case .night: return "Night"
        case .newsprint: return "Newsprint"
        case .vue: return "Vue"
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch self {
        case .auto: return nil
        case .night: return .dark
        case .githubLight, .newsprint, .vue: return .light
        }
    }

    var windowNSColor: NSColor {
        switch self {
        case .auto:
            return NSColor(name: nil) { appearance in
                let isDark = appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
                return isDark
                    ? NSColor(srgbRed: 0.067, green: 0.078, blue: 0.098, alpha: 1.0) // #111419
                    : NSColor.white
            }
        case .githubLight, .vue:
            return NSColor.white
        case .night:
            return NSColor(srgbRed: 0.106, green: 0.118, blue: 0.137, alpha: 1.0) // #1b1e23
        case .newsprint:
            return NSColor(srgbRed: 0.953, green: 0.949, blue: 0.933, alpha: 1.0) // #f3f2ee
        }
    }

    var windowBackground: Color {
        Color(nsColor: windowNSColor)
    }
}

enum PageWidth: Int, CaseIterable, Identifiable {
    case narrow = 720
    case standard = 860
    case wide = 1080
    case full = 0

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .narrow: return "Narrow (720px)"
        case .standard: return "Standard (860px)"
        case .wide: return "Wide (1080px)"
        case .full: return "Full Width"
        }
    }
}

final class ReaderPreferences: ObservableObject {
    static let shared = ReaderPreferences()

    private let defaults = UserDefaults.standard

    @Published var theme: ReaderTheme {
        didSet { defaults.set(theme.rawValue, forKey: "markread.theme") }
    }

    @Published var fontSize: Int {
        didSet { defaults.set(fontSize, forKey: "markread.fontSize") }
    }

    @Published var pageWidth: PageWidth {
        didSet { defaults.set(pageWidth.rawValue, forKey: "markread.pageWidth") }
    }

    @Published var showFrontMatter: Bool {
        didSet { defaults.set(showFrontMatter, forKey: "markread.showFrontMatter") }
    }

    @Published var language: AppLanguage {
        didSet { defaults.set(language.rawValue, forKey: "markread.language") }
    }

    var l10n: L10n {
        L10n(language)
    }

    private init() {
        let savedTheme = defaults.string(forKey: "markread.theme") ?? ReaderTheme.auto.rawValue
        self.theme = ReaderTheme(rawValue: savedTheme) ?? .auto

        let savedFontSize = defaults.integer(forKey: "markread.fontSize")
        self.fontSize = savedFontSize > 0 ? savedFontSize : 16

        if defaults.object(forKey: "markread.pageWidth") != nil {
            let savedWidth = defaults.integer(forKey: "markread.pageWidth")
            self.pageWidth = PageWidth(rawValue: savedWidth) ?? .standard
        } else {
            self.pageWidth = .standard
        }

        self.showFrontMatter = defaults.bool(forKey: "markread.showFrontMatter")

        let savedLang = defaults.string(forKey: "markread.language") ?? AppLanguage.system.rawValue
        self.language = AppLanguage(rawValue: savedLang) ?? .system
    }

    func zoomIn() {
        fontSize = min(fontSize + 1, 28)
    }

    func zoomOut() {
        fontSize = max(fontSize - 1, 12)
    }

    func resetZoom() {
        fontSize = 16
    }
}

import AppKit
import SwiftUI

struct WindowPayload: Codable, Hashable {
    let url: URL?
}

@Observable
final class AppRouter {
    static let shared = AppRouter()

    private var initialQueue: [URL] = []
    var incomingURLForEmptyWindow: URL?
    var openNewWindow: ((URL) -> Void)?

    private init() {
        // Parse CLI file arguments if launched via terminal: MarkRead path/to/file.md
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            guard !arg.hasPrefix("-") else { continue }
            let url = URL(fileURLWithPath: arg).standardizedFileURL
            if FileManager.default.fileExists(atPath: url.path) {
                initialQueue.append(url)
            }
        }
    }

    func enqueueExternalURLs(_ urls: [URL]) {
        for url in urls {
            if let openNewWindow {
                openNewWindow(url)
            } else {
                initialQueue.append(url)
                incomingURLForEmptyWindow = url
            }
        }
    }

    func claimInitialURL() -> URL? {
        guard !initialQueue.isEmpty else { return nil }
        return initialQueue.removeFirst()
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func application(_ application: NSApplication, open urls: [URL]) {
        AppRouter.shared.enqueueExternalURLs(urls)
    }
}

@main
struct MarkReadApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @FocusedValue(\.windowActions) private var windowActions

    private let preferences = ReaderPreferences.shared
    private var l10n: L10n { preferences.l10n }

    var body: some Scene {
        WindowGroup(id: "reader", for: WindowPayload.self) { $payload in
            ReaderWindowHost(initialURL: payload.url)
        } defaultValue: {
            WindowPayload(url: nil)
        }
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 960, height: 720)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(l10n.openMenu) {
                    windowActions?.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button(l10n.openShowcaseMenu) {
                    windowActions?.openSample()
                }

                Divider()

                Button(l10n.reloadFile) {
                    windowActions?.reload()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!(windowActions?.hasDocument ?? false))

                Button(l10n.revealInFinder) {
                    windowActions?.revealInFinder()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasFileURL ?? false))

                Divider()

                Button(l10n.exportPDF) {
                    windowActions?.exportPDF()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))

                Button(l10n.exportHTML) {
                    windowActions?.exportHTML()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))
            }

            CommandGroup(after: .textEditing) {
                Divider()

                Button(l10n.findMenu) {
                    windowActions?.showFind()
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(!(windowActions?.hasDocument ?? false))

                Button(l10n.findNext) {
                    windowActions?.findNext()
                }
                .keyboardShortcut("g", modifiers: .command)
                .disabled(!(windowActions?.hasDocument ?? false))

                Button(l10n.findPrevious) {
                    windowActions?.findPrev()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))
            }

            CommandMenu(l10n.viewMenu) {
                Button(l10n.toggleOutline) {
                    windowActions?.toggleSidebar()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))

                Button(preferences.showFrontMatter ? l10n.hideFrontMatter : l10n.showFrontMatter) {
                    preferences.showFrontMatter.toggle()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Divider()

                Menu(l10n.themeMenu) {
                    ForEach(ReaderTheme.allCases) { theme in
                        Button {
                            preferences.theme = theme
                        } label: {
                            if preferences.theme == theme {
                                Label(l10n.themeName(theme), systemImage: "checkmark")
                            } else {
                                Text(l10n.themeName(theme))
                            }
                        }
                    }
                }

                Menu(l10n.pageWidthMenu) {
                    ForEach(PageWidth.allCases) { width in
                        Button {
                            preferences.pageWidth = width
                        } label: {
                            if preferences.pageWidth == width {
                                Label(l10n.pageWidthName(width), systemImage: "checkmark")
                            } else {
                                Text(l10n.pageWidthName(width))
                            }
                        }
                    }
                }

                Menu(l10n.languageMenu) {
                    ForEach(AppLanguage.allCases) { lang in
                        Button {
                            preferences.language = lang
                        } label: {
                            if preferences.language == lang {
                                Label(lang.nativeName, systemImage: "checkmark")
                            } else {
                                Text(lang.nativeName)
                            }
                        }
                    }
                }

                Divider()

                Button(l10n.zoomIn) {
                    preferences.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button(l10n.zoomOut) {
                    preferences.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button(l10n.actualSize) {
                    preferences.resetZoom()
                }
                .keyboardShortcut("0", modifiers: .command)
            }
        }
    }
}

private struct ReaderWindowHost: View {
    let initialURL: URL?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        ReaderWindowView(initialURL: initialURL)
            .onAppear {
                AppRouter.shared.openNewWindow = { url in
                    openWindow(id: "reader", value: WindowPayload(url: url))
                }
            }
    }
}

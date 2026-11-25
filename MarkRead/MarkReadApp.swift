import AppKit
import SwiftUI

struct WindowPayload: Codable, Hashable {
    let url: URL?
}

final class AppRouter {
    static let shared = AppRouter()

    private var initialQueue: [URL] = []
    /// Windows currently showing the welcome screen, keyed by a per-window ID.
    /// External open requests fill one of these before spawning a new window.
    private var emptyWindowLoaders: [UUID: (URL) -> Void] = [:]
    private var emptyWindowOrder: [UUID] = []
    /// Windows currently showing a document.
    private(set) var documentWindowIDs: Set<UUID> = []
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
            if let id = emptyWindowOrder.first, let loader = emptyWindowLoaders[id] {
                unregisterEmptyWindow(id)
                loader(url)
            } else if let openNewWindow {
                openNewWindow(url)
            } else {
                // No window yet (cold launch): the first window claims it on appear.
                initialQueue.append(url)
            }
        }
    }

    func registerEmptyWindow(_ id: UUID, loader: @escaping (URL) -> Void) {
        if emptyWindowLoaders[id] == nil { emptyWindowOrder.append(id) }
        emptyWindowLoaders[id] = loader
    }

    func unregisterEmptyWindow(_ id: UUID) {
        emptyWindowLoaders[id] = nil
        emptyWindowOrder.removeAll { $0 == id }
    }

    func isEmptyWindowRegistered(_ id: UUID) -> Bool {
        emptyWindowLoaders[id] != nil
    }

    func setDocumentWindow(_ id: UUID, hasDocument: Bool) {
        if hasDocument {
            documentWindowIDs.insert(id)
        } else {
            documentWindowIDs.remove(id)
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

    @ObservedObject private var preferences = ReaderPreferences.shared
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
            // Finder "open" events are routed by AppDelegate/AppRouter. Without this,
            // SwiftUI also spawns an extra empty window for every external open event.
            .handlesExternalEvents(preferring: ["*"], allowing: ["*"])
            .onAppear {
                AppRouter.shared.openNewWindow = { url in
                    openWindow(id: "reader", value: WindowPayload(url: url))
                }
            }
    }
}

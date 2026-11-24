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
                Button("Open…") {
                    windowActions?.openFile()
                }
                .keyboardShortcut("o", modifiers: .command)

                Button("Open Showcase Document") {
                    windowActions?.openSample()
                }

                Divider()

                Button("Reload File") {
                    windowActions?.reload()
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(!(windowActions?.hasDocument ?? false))

                Button("Reveal in Finder") {
                    windowActions?.revealInFinder()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasFileURL ?? false))

                Divider()

                Button("Export as PDF…") {
                    windowActions?.exportPDF()
                }
                .keyboardShortcut("p", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))

                Button("Export as HTML…") {
                    windowActions?.exportHTML()
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))
            }

            CommandGroup(after: .textEditing) {
                Divider()

                Button("Find…") {
                    windowActions?.showFind()
                }
                .keyboardShortcut("f", modifiers: .command)
                .disabled(!(windowActions?.hasDocument ?? false))

                Button("Find Next") {
                    windowActions?.findNext()
                }
                .keyboardShortcut("g", modifiers: .command)
                .disabled(!(windowActions?.hasDocument ?? false))

                Button("Find Previous") {
                    windowActions?.findPrev()
                }
                .keyboardShortcut("g", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))
            }

            CommandMenu("View") {
                Button("Toggle Outline") {
                    windowActions?.toggleSidebar()
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
                .disabled(!(windowActions?.hasDocument ?? false))

                Button(preferences.showFrontMatter ? "Hide Front Matter" : "Show Front Matter") {
                    preferences.showFrontMatter.toggle()
                }
                .keyboardShortcut("m", modifiers: [.command, .shift])

                Divider()

                Menu("Theme") {
                    ForEach(ReaderTheme.allCases) { theme in
                        Button {
                            preferences.theme = theme
                        } label: {
                            if preferences.theme == theme {
                                Label(theme.displayName, systemImage: "checkmark")
                            } else {
                                Text(theme.displayName)
                            }
                        }
                    }
                }

                Menu("Page Width") {
                    ForEach(PageWidth.allCases) { width in
                        Button {
                            preferences.pageWidth = width
                        } label: {
                            if preferences.pageWidth == width {
                                Label(width.displayName, systemImage: "checkmark")
                            } else {
                                Text(width.displayName)
                            }
                        }
                    }
                }

                Divider()

                Button("Zoom In") {
                    preferences.zoomIn()
                }
                .keyboardShortcut("+", modifiers: .command)

                Button("Zoom Out") {
                    preferences.zoomOut()
                }
                .keyboardShortcut("-", modifiers: .command)

                Button("Actual Size") {
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

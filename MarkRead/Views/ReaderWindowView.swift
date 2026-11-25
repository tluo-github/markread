import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct WindowActions {
    let openFile: () -> Void
    let openSample: () -> Void
    let reload: () -> Void
    let revealInFinder: () -> Void
    let toggleSidebar: () -> Void
    let showFind: () -> Void
    let findNext: () -> Void
    let findPrev: () -> Void
    let exportPDF: () -> Void
    let exportHTML: () -> Void
    let hasDocument: Bool
    let hasFileURL: Bool
}

/// Weak handle to the NSWindow hosting a reader view.
final class WindowReference {
    weak var window: NSWindow?
}

private struct WindowChromeSync: NSViewRepresentable {
    let backgroundColor: NSColor
    let windowRef: WindowReference

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            apply(to: view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            apply(to: nsView.window)
        }
    }

    private func apply(to window: NSWindow?) {
        guard let window else { return }
        windowRef.window = window
        window.titlebarAppearsTransparent = true
        window.backgroundColor = backgroundColor
    }
}

private struct WindowActionsKey: FocusedValueKey {
    typealias Value = WindowActions
}

extension FocusedValues {
    var windowActions: WindowActions? {
        get { self[WindowActionsKey.self] }
        set { self[WindowActionsKey.self] = newValue }
    }
}

struct ReaderWindowView: View {
    let initialURL: URL?

    @StateObject private var document = MarkdownDocumentState()
    @StateObject private var webController = WebViewController()
    @State private var showSidebar = false
    @State private var isFindVisible = false
    @State private var findQuery = ""
    @State private var isDropTargeted = false
    @State private var windowID = UUID()
    @State private var windowRef = WindowReference()

    @ObservedObject private var preferences = ReaderPreferences.shared
    private let router = AppRouter.shared

    private var l10n: L10n { preferences.l10n }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                if showSidebar && document.hasDocument {
                    TOCSidebarView(
                        headings: document.headings,
                        activeHeadingID: document.activeHeadingID,
                        wordCount: document.wordCount,
                        readingMinutes: document.readingMinutes,
                        l10n: l10n
                    ) { item in
                        webController.scrollToHeading(item.id)
                    }
                    Divider()
                }

                Group {
                    if document.hasDocument {
                        MarkdownWebView(
                            document: document,
                            preferences: preferences,
                            controller: webController,
                            onFileDrop: { url in
                                document.load(url: url, preserveScroll: false)
                            },
                            onDragHoverChanged: { hovering in
                                isDropTargeted = hovering
                            }
                        )
                    } else {
                        WelcomeView(
                            l10n: l10n,
                            onOpenFile: openFilePanel,
                            onOpenSample: { document.loadSample() }
                        )
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if isFindVisible && document.hasDocument {
                FindBarView(
                    query: $findQuery,
                    currentMatch: webController.findCurrent,
                    totalMatches: webController.findTotal,
                    l10n: l10n,
                    onSearchChanged: { webController.find($0) },
                    onNext: { webController.findNext() },
                    onPrev: { webController.findPrev() },
                    onClose: closeFind
                )
                .padding(.top, 12)
                .padding(.trailing, 18)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            if isDropTargeted {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 2.5, dash: [8, 6]))
                    .background(Color.accentColor.opacity(0.08).clipShape(RoundedRectangle(cornerRadius: 12)))
                    .overlay {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.down.doc")
                                .font(.system(size: 32, weight: .light))
                            Text(l10n.dropPrompt)
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .background(preferences.theme.windowBackground)
        .background(WindowChromeSync(backgroundColor: preferences.theme.windowNSColor, windowRef: windowRef))
        .preferredColorScheme(preferences.theme.preferredColorScheme)
        .navigationTitle(document.title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showSidebar.toggle()
                    }
                } label: {
                    Image(systemName: "sidebar.left")
                }
                .disabled(!document.hasDocument)
                .help(l10n.toggleOutlineTip)
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if document.hasDocument {
                    Button {
                        openFind()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .help(l10n.findTip)
                }

                Menu {
                    Section(l10n.themeMenu) {
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

                    Divider()

                    Section(l10n.pageWidthMenu) {
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

                    Divider()

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

                    Button {
                        preferences.showFrontMatter.toggle()
                    } label: {
                        if preferences.showFrontMatter {
                            Label(l10n.showFrontMatter, systemImage: "checkmark")
                        } else {
                            Text(l10n.showFrontMatter)
                        }
                    }

                    Divider()

                    Button("\(l10n.zoomIn) (⌘+)") { preferences.zoomIn() }
                    Button("\(l10n.zoomOut) (⌘-)") { preferences.zoomOut() }
                    Button("\(l10n.actualSize) (⌘0)") { preferences.resetZoom() }
                } label: {
                    Image(systemName: "textformat.size")
                }
                .help(l10n.appearanceTip)
            }
        }
        .onDrop(of: [.fileURL], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
        }
        .onAppear {
            if let initialURL {
                document.load(url: initialURL, preserveScroll: false)
            } else if let pending = router.claimInitialURL() {
                document.load(url: pending, preserveScroll: false)
            }
            updateEmptyWindowRegistration()
        }
        .onDisappear {
            router.unregisterEmptyWindow(windowID)
            router.setDocumentWindow(windowID, hasDocument: false)
        }
        .onChange(of: document.hasDocument) { _ in
            updateEmptyWindowRegistration()
        }
        .focusedSceneValue(
            \.windowActions,
            WindowActions(
                openFile: openFilePanel,
                openSample: { document.loadSample() },
                reload: { document.reload(preserveScroll: true) },
                revealInFinder: {
                    if let url = document.fileURL {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                },
                toggleSidebar: {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        showSidebar.toggle()
                    }
                },
                showFind: openFind,
                findNext: { webController.findNext() },
                findPrev: { webController.findPrev() },
                exportPDF: {
                    let base = document.fileURL?.deletingPathExtension().lastPathComponent ?? "MarkRead"
                    webController.exportPDF(suggestedName: base)
                },
                exportHTML: {
                    let base = document.fileURL?.deletingPathExtension().lastPathComponent ?? "MarkRead"
                    webController.exportHTML(suggestedName: base, title: document.title)
                },
                hasDocument: document.hasDocument,
                hasFileURL: document.fileURL != nil
            )
        )
        .alert(
            l10n.openErrorTitle,
            isPresented: Binding(
                get: { document.errorMessage != nil },
                set: { if !$0 { document.errorMessage = nil } }
            )
        ) {
            Button(l10n.okButton, role: .cancel) {}
        } message: {
            Text(document.errorMessage ?? "")
        }
    }

    private func openFind() {
        guard document.hasDocument else { return }
        withAnimation(.easeInOut(duration: 0.15)) {
            isFindVisible = true
        }
    }

    private func closeFind() {
        withAnimation(.easeInOut(duration: 0.15)) {
            isFindVisible = false
        }
        findQuery = ""
        webController.clearFind()
    }

    private func openFilePanel() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [
            UTType(filenameExtension: "md") ?? .plainText,
            UTType(filenameExtension: "markdown") ?? .plainText,
            .plainText
        ]
        if panel.runModal() == .OK, let url = panel.url {
            document.load(url: url, preserveScroll: false)
        }
    }

    /// Lets the router route Finder "open" events into this window while it shows the welcome screen.
    private func updateEmptyWindowRegistration() {
        router.setDocumentWindow(windowID, hasDocument: document.hasDocument)
        if document.hasDocument {
            router.unregisterEmptyWindow(windowID)
        } else {
            let doc = document
            router.registerEmptyWindow(windowID) { url in
                doc.load(url: url, preserveScroll: false)
            }
            closeIfRedundant()
        }
    }

    /// During launch SwiftUI may create more than one window (default window, restored
    /// windows, a window for the Finder open event) in an unpredictable order. A welcome
    /// window next to a window that already shows a document is never wanted, so close it.
    /// The delay lets SwiftUI's short-lived placeholder views disappear first, and lets a
    /// pending open event fill this window instead.
    private func closeIfRedundant() {
        let id = windowID
        let doc = document
        let ref = windowRef
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            guard router.isEmptyWindowRegistered(id),
                  !doc.hasDocument,
                  !router.documentWindowIDs.subtracting([id]).isEmpty
            else { return }
            router.unregisterEmptyWindow(id)
            ref.window?.close()
        }
    }

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            DispatchQueue.main.async {
                document.load(url: url, preserveScroll: false)
            }
        }
        return true
    }
}

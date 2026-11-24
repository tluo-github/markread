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

private struct WindowChromeSync: NSViewRepresentable {
    let backgroundColor: NSColor

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

    @State private var document = MarkdownDocumentState()
    @State private var webController = WebViewController()
    @State private var showSidebar = false
    @State private var isFindVisible = false
    @State private var findQuery = ""
    @State private var isDropTargeted = false

    private let preferences = ReaderPreferences.shared
    private let router = AppRouter.shared

    var body: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 0) {
                if showSidebar && document.hasDocument {
                    TOCSidebarView(
                        headings: document.headings,
                        activeHeadingID: document.activeHeadingID,
                        wordCount: document.wordCount,
                        readingMinutes: document.readingMinutes
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
                            Text("Drop to read Markdown")
                                .font(.system(size: 14, weight: .medium))
                        }
                        .foregroundStyle(Color.accentColor)
                    }
                    .padding(14)
                    .allowsHitTesting(false)
            }
        }
        .background(preferences.theme.windowBackground)
        .background(WindowChromeSync(backgroundColor: preferences.theme.windowNSColor))
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
                .help("Toggle Outline (⇧⌘O)")
            }

            ToolbarItemGroup(placement: .primaryAction) {
                if document.hasDocument {
                    Button {
                        openFind()
                    } label: {
                        Image(systemName: "magnifyingglass")
                    }
                    .help("Find in Document (⌘F)")
                }

                Menu {
                    Section("Theme") {
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

                    Divider()

                    Section("Page Width") {
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

                    Button {
                        preferences.showFrontMatter.toggle()
                    } label: {
                        if preferences.showFrontMatter {
                            Label("Show Front Matter", systemImage: "checkmark")
                        } else {
                            Text("Show Front Matter")
                        }
                    }

                    Divider()

                    Button("Zoom In (⌘+)") { preferences.zoomIn() }
                    Button("Zoom Out (⌘-)") { preferences.zoomOut() }
                    Button("Actual Size (⌘0)") { preferences.resetZoom() }
                } label: {
                    Image(systemName: "textformat.size")
                }
                .help("Appearance & Themes")
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
        }
        .onChange(of: router.incomingURLForEmptyWindow) { _, newURL in
            if let url = newURL, !document.hasDocument {
                document.load(url: url, preserveScroll: false)
                router.incomingURLForEmptyWindow = nil
            }
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
            "Unable to Open File",
            isPresented: Binding(
                get: { document.errorMessage != nil },
                set: { if !$0 { document.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
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

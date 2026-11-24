import AppKit
import SwiftUI
import UniformTypeIdentifiers
import WebKit

@Observable
final class WebViewController {
    fileprivate weak var webView: WKWebView?
    fileprivate var isPageReady = false
    fileprivate var pendingRenderJS: String?

    var findTotal: Int = 0
    var findCurrent: Int = 0

    func evaluate(_ js: String) {
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    func scrollToHeading(_ id: String) {
        guard let encoded = encodeJSON(id) else { return }
        evaluate("window.MarkRead && window.MarkRead.scrollToHeading(\(encoded));")
    }

    func find(_ query: String) {
        guard let encoded = encodeJSON(query) else { return }
        evaluate("window.MarkRead && window.MarkRead.find(\(encoded));")
    }

    func findNext() {
        evaluate("window.MarkRead && window.MarkRead.findNext();")
    }

    func findPrev() {
        evaluate("window.MarkRead && window.MarkRead.findPrev();")
    }

    func clearFind() {
        findTotal = 0
        findCurrent = 0
        evaluate("window.MarkRead && window.MarkRead.clearFind();")
    }

    func exportPDF(suggestedName: String) {
        guard let webView else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(suggestedName).pdf"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let config = WKPDFConfiguration()
            webView.createPDF(configuration: config) { result in
                if case .success(let data) = result {
                    try? data.write(to: url, options: .atomic)
                }
            }
        }
    }

    func exportHTML(suggestedName: String, title: String) {
        guard let webView, let encodedTitle = encodeJSON(title) else { return }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.html]
        panel.nameFieldStringValue = "\(suggestedName).html"
        panel.canCreateDirectories = true

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            webView.evaluateJavaScript("window.MarkRead.getStandaloneHTML(\(encodedTitle));") { value, _ in
                if let html = value as? String {
                    try? html.write(to: url, atomically: true, encoding: .utf8)
                }
            }
        }
    }

    fileprivate func render(
        markdown: String,
        theme: ReaderTheme,
        fontSize: Int,
        pageWidth: PageWidth,
        showFrontMatter: Bool,
        preserveScroll: Bool
    ) {
        let payload: [String: Any] = [
            "markdown": markdown,
            "theme": theme.rawValue,
            "fontSize": fontSize,
            "pageWidth": pageWidth.rawValue,
            "showFrontMatter": showFrontMatter,
            "preserveScroll": preserveScroll
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        let js = "window.MarkRead && window.MarkRead.render(\(json));"

        if isPageReady {
            evaluate(js)
        } else {
            pendingRenderJS = js
        }
    }

    fileprivate func updatePreferences(
        theme: ReaderTheme,
        fontSize: Int,
        pageWidth: PageWidth,
        showFrontMatter: Bool
    ) {
        guard isPageReady else { return }
        let payload: [String: Any] = [
            "theme": theme.rawValue,
            "fontSize": fontSize,
            "pageWidth": pageWidth.rawValue,
            "showFrontMatter": showFrontMatter
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: data, encoding: .utf8) else { return }
        evaluate("window.MarkRead && window.MarkRead.updatePreferences(\(json));")
    }

    private func encodeJSON(_ value: String) -> String? {
        guard let data = try? JSONEncoder().encode(value) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

final class DropAwareWebView: WKWebView {
    var onFileDrop: ((URL) -> Void)?
    var onDragHoverChanged: ((Bool) -> Void)?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func extractMarkdownURL(from info: NSDraggingInfo) -> URL? {
        guard let urls = info.draggingPasteboard.readObjects(
            forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]
        ) as? [URL] else {
            return nil
        }
        return urls.first { isReadableMarkdown($0) }
    }

    private func isReadableMarkdown(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["md", "markdown", "mdown", "mkd", "mkdn", "mdtxt", "mdtext", "txt"].contains(ext)
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        if extractMarkdownURL(from: sender) != nil {
            onDragHoverChanged?(true)
            return .copy
        }
        return []
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        if extractMarkdownURL(from: sender) != nil {
            return .copy
        }
        return []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragHoverChanged?(false)
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        onDragHoverChanged?(false)
        guard let url = extractMarkdownURL(from: sender) else {
            return false
        }
        onFileDrop?(url)
        return true
    }
}

struct MarkdownWebView: NSViewRepresentable {
    let document: MarkdownDocumentState
    let preferences: ReaderPreferences
    let controller: WebViewController
    let onFileDrop: (URL) -> Void
    let onDragHoverChanged: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(document: document, controller: controller)
    }

    func makeNSView(context: Context) -> DropAwareWebView {
        let config = WKWebViewConfiguration()
        let schemeHandler = LocalResourceSchemeHandler { [weak document] in
            document?.baseDirectoryURL
        }
        config.setURLSchemeHandler(schemeHandler, forURLScheme: LocalResourceSchemeHandler.assetScheme)
        config.setURLSchemeHandler(schemeHandler, forURLScheme: LocalResourceSchemeHandler.localFileScheme)

        config.userContentController.add(context.coordinator, name: "markread")
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        let webView = DropAwareWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.onFileDrop = onFileDrop
        webView.onDragHoverChanged = onDragHoverChanged

        controller.webView = webView

        if let entryURL = URL(string: "\(LocalResourceSchemeHandler.assetScheme)://app/index.html") {
            webView.load(URLRequest(url: entryURL))
        }
        return webView
    }

    func updateNSView(_ webView: DropAwareWebView, context: Context) {
        webView.onFileDrop = onFileDrop
        webView.onDragHoverChanged = onDragHoverChanged

        if context.coordinator.lastRenderVersion != document.renderVersion {
            context.coordinator.lastRenderVersion = document.renderVersion
            controller.render(
                markdown: document.content,
                theme: preferences.theme,
                fontSize: preferences.fontSize,
                pageWidth: preferences.pageWidth,
                showFrontMatter: preferences.showFrontMatter,
                preserveScroll: document.preserveScrollOnNextRender
            )
            context.coordinator.lastTheme = preferences.theme
            context.coordinator.lastFontSize = preferences.fontSize
            context.coordinator.lastPageWidth = preferences.pageWidth
            context.coordinator.lastShowFrontMatter = preferences.showFrontMatter
        } else if context.coordinator.lastTheme != preferences.theme
            || context.coordinator.lastFontSize != preferences.fontSize
            || context.coordinator.lastPageWidth != preferences.pageWidth
            || context.coordinator.lastShowFrontMatter != preferences.showFrontMatter
        {
            context.coordinator.lastTheme = preferences.theme
            context.coordinator.lastFontSize = preferences.fontSize
            context.coordinator.lastPageWidth = preferences.pageWidth
            context.coordinator.lastShowFrontMatter = preferences.showFrontMatter
            controller.updatePreferences(
                theme: preferences.theme,
                fontSize: preferences.fontSize,
                pageWidth: preferences.pageWidth,
                showFrontMatter: preferences.showFrontMatter
            )
        }
    }

    final class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let document: MarkdownDocumentState
        let controller: WebViewController

        var lastRenderVersion: UUID?
        var lastTheme: ReaderTheme?
        var lastFontSize: Int?
        var lastPageWidth: PageWidth?
        var lastShowFrontMatter: Bool?

        init(document: MarkdownDocumentState, controller: WebViewController) {
            self.document = document
            self.controller = controller
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            guard message.name == "markread",
                  let dict = message.body as? [String: Any],
                  let type = dict["type"] as? String else {
                return
            }

            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                switch type {
                case "ready":
                    self.controller.isPageReady = true
                    if let pending = self.controller.pendingRenderJS {
                        self.controller.pendingRenderJS = nil
                        self.controller.evaluate(pending)
                    }
                case "toc":
                    if let items = dict["items"],
                       let data = try? JSONSerialization.data(withJSONObject: items),
                       let decoded = try? JSONDecoder().decode([TOCItem].self, from: data) {
                        self.document.headings = decoded
                    }
                case "activeHeading":
                    if let id = dict["id"] as? String {
                        self.document.activeHeadingID = id
                    }
                case "findResult":
                    self.controller.findCurrent = dict["current"] as? Int ?? 0
                    self.controller.findTotal = dict["total"] as? Int ?? 0
                case "copyText":
                    if let text = dict["text"] as? String {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(text, forType: .string)
                    }
                case "openExternal":
                    if let urlStr = dict["url"] as? String, let url = URL(string: urlStr) {
                        NSWorkspace.shared.open(url)
                    }
                case "openRelativeMarkdown":
                    if let path = dict["path"] as? String {
                        self.document.openRelativeMarkdown(path: path)
                    }
                default:
                    break
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard let url = navigationAction.request.url else {
                decisionHandler(.cancel)
                return
            }
            if url.scheme == LocalResourceSchemeHandler.assetScheme
                || url.scheme == LocalResourceSchemeHandler.localFileScheme {
                decisionHandler(.allow)
                return
            }
            if navigationAction.navigationType == .linkActivated {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
    }
}

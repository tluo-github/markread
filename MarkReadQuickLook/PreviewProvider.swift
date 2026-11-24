import Foundation
import JavaScriptCore
import Quartz
import UniformTypeIdentifiers

final class PreviewProvider: QLPreviewProvider, QLPreviewingController {
    private static let rendererQueue = DispatchQueue(label: "com.markread.quicklook.js")
    private static var cachedContext: JSContext?
    private static var cachedCSS: String = ""

    func providePreview(for request: QLFilePreviewRequest) async throws -> QLPreviewReply {
        let fileURL = request.fileURL
        let markdown = try readMarkdownText(from: fileURL)
        let title = fileURL.lastPathComponent
        let html = Self.renderHTML(markdown: markdown, title: title)

        let data = Data(html.utf8)
        let reply = QLPreviewReply(
            dataOfContentType: .html,
            contentSize: CGSize(width: 880, height: 680)
        ) { _ in
            return data
        }
        reply.stringEncoding = .utf8
        reply.title = title
        return reply
    }

    private func readMarkdownText(from url: URL) throws -> String {
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            return utf8
        }
        var detectedEncoding: String.Encoding = .utf8
        return try String(contentsOf: url, usedEncoding: &detectedEncoding)
    }

    private static func renderHTML(markdown: String, title: String) -> String {
        rendererQueue.sync {
            let context = makeOrGetContext()
            guard let fn = context.objectForKeyedSubscript("renderQuickLookHTML"),
                  let result = fn.call(withArguments: [markdown, cachedCSS, title, false]),
                  !result.isUndefined,
                  !result.isNull,
                  let html = result.toString() else {
                return fallbackHTML(markdown: markdown, title: title)
            }
            return html
        }
    }

    private static func makeOrGetContext() -> JSContext {
        if let existing = cachedContext {
            return existing
        }

        let ctx = JSContext()!
        ctx.evaluateScript("var window = this; var self = this;")

        let bundle = Bundle(for: PreviewProvider.self)
        if let webDir = bundle.resourceURL?.appendingPathComponent("web", isDirectory: true) {
            let vendorDir = webDir.appendingPathComponent("vendor", isDirectory: true)
            if let css = try? String(contentsOf: webDir.appendingPathComponent("themes.css"), encoding: .utf8) {
                cachedCSS = css
            }
            if let mdJS = try? String(contentsOf: vendorDir.appendingPathComponent("markdown-it.min.js"), encoding: .utf8) {
                ctx.evaluateScript(mdJS)
            }
            if let hlJS = try? String(contentsOf: vendorDir.appendingPathComponent("highlight.min.js"), encoding: .utf8) {
                ctx.evaluateScript(hlJS)
            }
            if let qlJS = try? String(contentsOf: webDir.appendingPathComponent("quicklook-render.js"), encoding: .utf8) {
                ctx.evaluateScript(qlJS)
            }
        }

        cachedContext = ctx
        return ctx
    }

    private static func fallbackHTML(markdown: String, title: String) -> String {
        let escaped = markdown
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
        return """
        <!DOCTYPE html>
        <html><head><meta charset="utf-8"><title>\(title)</title></head>
        <body style="font-family: -apple-system, sans-serif; padding: 24px;"><pre style="white-space: pre-wrap;">\(escaped)</pre></body></html>
        """
    }
}

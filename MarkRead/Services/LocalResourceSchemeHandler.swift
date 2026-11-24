import Foundation
import UniformTypeIdentifiers
import WebKit

/// Serves offline bundled web assets (`markread-asset://app/...`)
/// and local document resources such as relative images (`markread-local://file/...`).
final class LocalResourceSchemeHandler: NSObject, WKURLSchemeHandler {
    static let assetScheme = "markread-asset"
    static let localFileScheme = "markread-local"

    private let baseDirectoryProvider: () -> URL?

    init(baseDirectoryProvider: @escaping () -> URL?) {
        self.baseDirectoryProvider = baseDirectoryProvider
        super.init()
    }

    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        guard let url = urlSchemeTask.request.url else {
            urlSchemeTask.didFailWithError(URLError(.badURL))
            return
        }

        switch url.scheme {
        case Self.assetScheme:
            serveBundledAsset(url: url, task: urlSchemeTask)
        case Self.localFileScheme:
            serveLocalDocumentResource(url: url, task: urlSchemeTask)
        default:
            urlSchemeTask.didFailWithError(URLError(.unsupportedURL))
        }
    }

    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        // Synchronous local reads complete immediately.
    }

    private func serveBundledAsset(url: URL, task: WKURLSchemeTask) {
        guard let webRoot = Bundle.main.resourceURL?.appendingPathComponent("web", isDirectory: true) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        let relativePath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let targetURL = webRoot.appendingPathComponent(relativePath).standardizedFileURL

        guard targetURL.path.hasPrefix(webRoot.standardizedFileURL.path),
              let data = try? Data(contentsOf: targetURL) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        respond(task: task, url: url, data: data, fileURL: targetURL)
    }

    private func serveLocalDocumentResource(url: URL, task: WKURLSchemeTask) {
        let decodedPath = url.path.removingPercentEncoding ?? url.path
        let trimmed = decodedPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        let targetURL: URL
        if decodedPath.hasPrefix("//") {
            targetURL = URL(fileURLWithPath: String(decodedPath.dropFirst())).standardizedFileURL
        } else if let baseDir = baseDirectoryProvider() {
            targetURL = URL(fileURLWithPath: trimmed, relativeTo: baseDir).standardizedFileURL
        } else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        guard let data = try? Data(contentsOf: targetURL) else {
            task.didFailWithError(URLError(.fileDoesNotExist))
            return
        }

        respond(task: task, url: url, data: data, fileURL: targetURL)
    }

    private func respond(task: WKURLSchemeTask, url: URL, data: Data, fileURL: URL) {
        let mimeType = mimeTypeForURL(fileURL)
        let response = URLResponse(
            url: url,
            mimeType: mimeType,
            expectedContentLength: data.count,
            textEncodingName: mimeType.hasPrefix("text/") || mimeType == "application/javascript" ? "utf-8" : nil
        )
        task.didReceive(response)
        task.didReceive(data)
        task.didFinish()
    }

    private func mimeTypeForURL(_ url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "html", "htm": return "text/html"
        case "css": return "text/css"
        case "js": return "application/javascript"
        case "svg": return "image/svg+xml"
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        case "json": return "application/json"
        default:
            if let utType = UTType(filenameExtension: url.pathExtension),
               let mime = utType.preferredMIMEType {
                return mime
            }
            return "application/octet-stream"
        }
    }
}

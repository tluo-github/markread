import Foundation

@Observable
final class MarkdownDocumentState {
    var fileURL: URL?
    var content: String = ""
    var title: String = "MarkRead"
    var headings: [TOCItem] = []
    var activeHeadingID: String?
    var wordCount: Int = 0
    var readingMinutes: Int = 1
    var errorMessage: String?
    var isSample: Bool = false
    var renderVersion: UUID = UUID()
    var preserveScrollOnNextRender: Bool = false

    private var fileWatcher: FileWatcher?

    var hasDocument: Bool {
        fileURL != nil || isSample
    }

    var baseDirectoryURL: URL? {
        fileURL?.deletingLastPathComponent()
    }

    func load(url: URL, preserveScroll: Bool = false) {
        let standardized = url.standardizedFileURL
        do {
            let text = try String(contentsOf: standardized, encoding: .utf8)
            self.fileURL = standardized
            self.isSample = false
            self.content = text
            self.title = standardized.lastPathComponent
            self.errorMessage = nil
            self.preserveScrollOnNextRender = preserveScroll
            self.updateStats(from: text)
            self.renderVersion = UUID()
            self.watchFile(standardized)
        } catch {
            self.errorMessage = "Unable to open \(standardized.lastPathComponent): \(error.localizedDescription)"
        }
    }

    func loadSample() {
        stopWatching()
        if let sampleURL = Bundle.main.url(forResource: "Sample", withExtension: "md"),
           let text = try? String(contentsOf: sampleURL, encoding: .utf8) {
            self.fileURL = nil
            self.isSample = true
            self.content = text
            self.title = "Sample.md"
            self.errorMessage = nil
            self.preserveScrollOnNextRender = false
            self.updateStats(from: text)
            self.renderVersion = UUID()
        }
    }

    func reload(preserveScroll: Bool = true) {
        guard let url = fileURL else { return }
        load(url: url, preserveScroll: preserveScroll)
    }

    func openRelativeMarkdown(path: String) {
        guard let baseDir = baseDirectoryURL else { return }
        let targetURL = URL(fileURLWithPath: path, relativeTo: baseDir).standardizedFileURL
        guard FileManager.default.fileExists(atPath: targetURL.path) else { return }
        load(url: targetURL, preserveScroll: false)
    }

    func stopWatching() {
        fileWatcher?.stop()
        fileWatcher = nil
    }

    private func watchFile(_ url: URL) {
        fileWatcher?.stop()
        let watcher = FileWatcher(url: url) { [weak self] in
            DispatchQueue.main.async {
                self?.reload(preserveScroll: true)
            }
        }
        watcher.start()
        self.fileWatcher = watcher
    }

    private func updateStats(from text: String) {
        // Count CJK characters + whitespace-delimited words
        var cjkCount = 0
        var nonCJKBuffer = ""
        for scalar in text.unicodeScalars {
            if (0x4E00...0x9FFF).contains(scalar.value) || (0x3400...0x4DBF).contains(scalar.value) {
                cjkCount += 1
            } else {
                nonCJKBuffer.unicodeScalars.append(scalar)
            }
        }
        let latinWords = nonCJKBuffer.split { $0.isWhitespace || $0.isNewline }.count
        let total = cjkCount + latinWords
        self.wordCount = total
        self.readingMinutes = max(1, Int(ceil(Double(total) / 240.0)))
    }

    deinit {
        fileWatcher?.stop()
    }
}

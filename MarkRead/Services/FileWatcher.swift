import Foundation

/// Watches a local file for external edits, including atomic save-and-rename patterns
/// used by VS Code, Cursor, Vim, and Xcode.
final class FileWatcher {
    private let url: URL
    private let onChange: () -> Void
    private let queue = DispatchQueue(label: "com.markread.filewatcher", qos: .utility)

    private var fileDescriptor: Int32 = -1
    private var source: DispatchSourceFileSystemObject?
    private var debounceWorkItem: DispatchWorkItem?
    private var isStopped = false

    init(url: URL, onChange: @escaping () -> Void) {
        self.url = url
        self.onChange = onChange
    }

    func start() {
        queue.async { [weak self] in
            self?.isStopped = false
            self?.attach()
        }
    }

    func stop() {
        queue.async { [weak self] in
            self?.isStopped = true
            self?.debounceWorkItem?.cancel()
            self?.debounceWorkItem = nil
            self?.detach()
        }
    }

    private func attach() {
        detach()
        guard !isStopped else { return }

        let fd = open(url.path, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let eventMask: DispatchSource.FileSystemEvent = [.write, .extend, .attrib, .rename, .delete]
        let src = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: eventMask,
            queue: queue
        )

        src.setEventHandler { [weak self] in
            guard let self, !self.isStopped else { return }
            let flags = src.data
            let needsReattach = flags.contains(.rename) || flags.contains(.delete)
            self.scheduleReload(reattach: needsReattach)
        }

        src.setCancelHandler { [fd] in
            close(fd)
        }

        self.source = src
        src.resume()
    }

    private func detach() {
        if let src = source {
            source = nil
            src.cancel()
        } else if fileDescriptor >= 0 {
            close(fileDescriptor)
        }
        fileDescriptor = -1
    }

    private func scheduleReload(reattach: Bool) {
        debounceWorkItem?.cancel()
        let work = DispatchWorkItem { [weak self] in
            guard let self, !self.isStopped else { return }
            if reattach {
                self.attach()
            }
            self.onChange()
        }
        debounceWorkItem = work
        queue.asyncAfter(deadline: .now() + 0.14, execute: work)
    }

    deinit {
        stop()
    }
}

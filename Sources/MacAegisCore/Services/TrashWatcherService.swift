import Foundation
import AppKit

public final class TrashWatcherService: @unchecked Sendable {
    public static let shared = TrashWatcherService()

    private var source: DispatchSourceFileSystemObject?
    private var fileDescriptor: Int32 = -1
    private let isRunningLock = NSLock()
    private var isRunning = false

    private init() {}

    public func startWatching() {
        isRunningLock.lock()
        defer { isRunningLock.unlock() }

        guard !isRunning else { return }

        let trashPath = FileUtils.expandPath("~/.Trash")
        fileDescriptor = open(trashPath, O_EVTONLY)
        guard fileDescriptor >= 0 else { return }

        let s = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fileDescriptor,
            eventMask: [.write, .extend, .attrib],
            queue: DispatchQueue.global(qos: .background)
        )

        s.setEventHandler { [weak self] in
            self?.handleTrashChange()
        }

        s.setCancelHandler { [weak self] in
            if let fd = self?.fileDescriptor, fd >= 0 {
                close(fd)
                self?.fileDescriptor = -1
            }
        }

        s.resume()
        self.source = s
        self.isRunning = true
    }

    public func stopWatching() {
        isRunningLock.lock()
        defer { isRunningLock.unlock() }

        guard isRunning else { return }
        source?.cancel()
        source = nil
        isRunning = false
    }

    private func handleTrashChange() {
        let trashPath = FileUtils.expandPath("~/.Trash")
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: trashPath) else { return }

        for file in files where file.hasSuffix(".app") {
            let appName = (file as NSString).deletingPathExtension
            DispatchQueue.main.async {
                NotificationCenter.default.post(
                    name: NSNotification.Name("MacAegisAppMovedToTrash"),
                    object: nil,
                    userInfo: ["appName": appName]
                )
            }
        }
    }
}

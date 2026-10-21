import Foundation

public enum CommandResult: Equatable {
    case exited(Int32)
    case timedOut
    case launchFailed
}

func shell(_ args: [String], timeout: TimeInterval = 15, completion: @escaping (CommandResult) -> Void) {
    DispatchQueue.global(qos: .userInitiated).async {
        let task = Process()
        let finished = DispatchSemaphore(value: 0)
        guard let executable = args.first, !executable.isEmpty else {
            DispatchQueue.main.async { completion(.launchFailed) }
            return
        }
        if executable.hasPrefix("/") {
            task.executableURL = URL(fileURLWithPath: executable)
            task.arguments = Array(args.dropFirst())
        } else {
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = args
        }
        task.standardInput = FileHandle.nullDevice
        task.standardOutput = FileHandle.nullDevice
        task.standardError = FileHandle.nullDevice
        task.terminationHandler = { _ in finished.signal() }
        do {
            try task.run()
        } catch {
            DispatchQueue.main.async { completion(.launchFailed) }
            return
        }

        let result: CommandResult
        if finished.wait(timeout: .now() + timeout) == .success {
            result = .exited(task.terminationStatus)
        } else {
            task.terminate()
            if finished.wait(timeout: .now() + 0.5) == .timedOut, task.isRunning {
                // Kill only the process launched here, never other browser/helper processes.
                kill(task.processIdentifier, SIGKILL)
                _ = finished.wait(timeout: .now() + 1)
            }
            result = .timedOut
        }
        task.terminationHandler = nil
        DispatchQueue.main.async { completion(result) }
    }
}

func loadJS(_ path: String) -> String {
    let bundlePath = Bundle.main.path(forResource: path, ofType: nil)!
    return try! String(contentsOfFile: bundlePath, encoding: String.Encoding.utf8)
}

func getModificationDate(fileManager: FileManager = FileManager.default, atPath: String) -> Date? {
    do {
        let fileManager = FileManager()
        let attributes = try fileManager.attributesOfItem(atPath: atPath)
        return attributes[FileAttributeKey.modificationDate] as? Date
    } catch {
        print("Error message: \(error.localizedDescription)")
        return nil
    }
}

let defaultUrlShorteners = [
    "adf.ly",
    "bit.do",
    "bit.ly",
    "buff.ly",
    "deck.ly",
    "fur.ly",
    "goo.gl",
    "is.gd",
    "mcaf.ee",
    "ow.ly",
    "spoti.fi",
    "su.pr",
    "t.co",
    "tiny.cc",
    "tinyurl.com",
    "urlshortener.teams.microsoft.com",
]

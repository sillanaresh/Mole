import Foundation

public enum MoleLocator {
    public static func locate(preferredPath: String? = nil, from startDirectory: URL? = nil) -> String? {
        if let preferredPath, isExecutable(preferredPath) {
            return preferredPath
        }

        for candidate in bundledCandidates() + upwardCandidates(from: startDirectory) + fixedCandidates() + pathCandidates() {
            if isExecutable(candidate) {
                return candidate
            }
        }

        return nil
    }

    public static func isExecutable(_ path: String) -> Bool {
        guard !path.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return false
        }
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
            && !isDirectory.boolValue
            && FileManager.default.isExecutableFile(atPath: path)
    }

    private static func bundledCandidates() -> [String] {
        var candidates: [String] = []
        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appendingPathComponent("Mole/mole").path)
            candidates.append(resourceURL.appendingPathComponent("mole").path)
            candidates.append(resourceURL.appendingPathComponent("mo").path)
        }
        return candidates
    }

    private static func upwardCandidates(from startDirectory: URL?) -> [String] {
        var candidates: [String] = []
        let start = startDirectory ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        var current = start.standardizedFileURL

        for _ in 0..<8 {
            candidates.append(current.appendingPathComponent("mole").path)
            candidates.append(current.appendingPathComponent("mo").path)
            let parent = current.deletingLastPathComponent()
            if parent.path == current.path {
                break
            }
            current = parent
        }

        return candidates
    }

    private static func fixedCandidates() -> [String] {
        [
            "/opt/homebrew/bin/mo",
            "/usr/local/bin/mo",
            "/opt/homebrew/bin/mole",
            "/usr/local/bin/mole"
        ]
    }

    private static func pathCandidates() -> [String] {
        let paths = (ProcessInfo.processInfo.environment["PATH"] ?? "")
            .split(separator: ":")
            .map(String.init)

        return paths.flatMap { directory in
            [
                URL(fileURLWithPath: directory).appendingPathComponent("mo").path,
                URL(fileURLWithPath: directory).appendingPathComponent("mole").path
            ]
        }
    }
}

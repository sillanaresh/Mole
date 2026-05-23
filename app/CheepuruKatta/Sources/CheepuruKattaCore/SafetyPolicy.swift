import Foundation

public enum SafetyPolicy {
    public static let protectedPrefixes: [String] = [
        "/",
        "/System",
        "/Library/Apple",
        "/bin",
        "/sbin",
        "/usr/bin",
        "/usr/sbin",
        "/etc",
        "/var/db"
    ]

    public static func protectedReason(forPath path: String) -> String? {
        let standardized = URL(fileURLWithPath: path).standardizedFileURL.path
        for prefix in protectedPrefixes {
            if standardized == prefix || (prefix != "/" && standardized.hasPrefix(prefix + "/")) {
                return "Protected macOS path"
            }
        }
        if standardized.contains("/Library/Keychains") || standardized.contains("/Library/Messages") {
            return "Protected personal data"
        }
        return nil
    }
}

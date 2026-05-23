import Foundation

public struct AnalyzeReport: Codable, Equatable, Sendable {
    public var path: String
    public var overview: Bool
    public var entries: [AnalyzeEntry]
    public var largeFiles: [AnalyzeFileEntry]?
    public var totalSize: Int64
    public var totalFiles: Int64?

    enum CodingKeys: String, CodingKey {
        case path
        case overview
        case entries
        case largeFiles = "large_files"
        case totalSize = "total_size"
        case totalFiles = "total_files"
    }
}

public struct AnalyzeEntry: Codable, Equatable, Sendable, Identifiable {
    public var id: String { path }
    public var name: String
    public var path: String
    public var size: Int64
    public var isDir: Bool
    public var insight: Bool?
    public var cleanable: Bool?
    public var lastAccess: String?

    enum CodingKeys: String, CodingKey {
        case name
        case path
        case size
        case isDir = "is_dir"
        case insight
        case cleanable
        case lastAccess = "last_access"
    }
}

public struct AnalyzeFileEntry: Codable, Equatable, Sendable, Identifiable {
    public var id: String { path }
    public var name: String
    public var path: String
    public var size: Int64
}

import Foundation

public struct MoleInvocation: Equatable, Sendable {
    public var arguments: [String]
    public var environment: [String: String]
    public var standardInput: String?
    public var timeoutSeconds: TimeInterval

    public init(
        arguments: [String],
        environment: [String: String] = [:],
        standardInput: String? = nil,
        timeoutSeconds: TimeInterval = 300
    ) {
        self.arguments = arguments
        self.environment = environment
        self.standardInput = standardInput
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct CommandResult: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var commandLine: String
    public var arguments: [String]
    public var startedAt: Date
    public var finishedAt: Date
    public var exitCode: Int32
    public var stdout: String
    public var stderr: String
    public var timedOut: Bool

    public init(
        id: UUID = UUID(),
        commandLine: String,
        arguments: [String],
        startedAt: Date,
        finishedAt: Date,
        exitCode: Int32,
        stdout: String,
        stderr: String,
        timedOut: Bool = false
    ) {
        self.id = id
        self.commandLine = commandLine
        self.arguments = arguments
        self.startedAt = startedAt
        self.finishedAt = finishedAt
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
        self.timedOut = timedOut
    }

    public var succeeded: Bool {
        exitCode == 0 && !timedOut
    }

    public var duration: TimeInterval {
        finishedAt.timeIntervalSince(startedAt)
    }

    public var combinedOutput: String {
        [stdout, stderr]
            .filter { !$0.isEmpty }
            .joined(separator: "\n")
            .strippingANSI()
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public struct ReviewSession: Identifiable, Equatable, Hashable, Sendable {
    public var id: UUID
    public var tool: MoleTool
    public var target: String?
    public var preview: CommandResult
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        tool: MoleTool,
        target: String?,
        preview: CommandResult,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.tool = tool
        self.target = target
        self.preview = preview
        self.createdAt = createdAt
    }
}

public struct HistoryEntry: Codable, Equatable, Hashable, Identifiable, Sendable {
    public var id: UUID
    public var tool: MoleTool
    public var target: String?
    public var startedAt: Date
    public var completedAt: Date
    public var previewExitCode: Int32
    public var executionExitCode: Int32
    public var succeeded: Bool
    public var timedOut: Bool
    public var commandLine: String
    public var outputPreview: String

    public init(
        id: UUID = UUID(),
        tool: MoleTool,
        target: String?,
        startedAt: Date,
        completedAt: Date,
        previewExitCode: Int32,
        executionExitCode: Int32,
        succeeded: Bool,
        timedOut: Bool,
        commandLine: String,
        outputPreview: String
    ) {
        self.id = id
        self.tool = tool
        self.target = target
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.previewExitCode = previewExitCode
        self.executionExitCode = executionExitCode
        self.succeeded = succeeded
        self.timedOut = timedOut
        self.commandLine = commandLine
        self.outputPreview = outputPreview
    }
}

public struct AppSettings: Codable, Equatable, Sendable {
    public var moleBinaryPath: String
    public var supportURL: String
    public var skipPrivilegedAuthorization: Bool
    public var commandTimeoutSeconds: TimeInterval

    public init(
        moleBinaryPath: String = "",
        supportURL: String = "",
        skipPrivilegedAuthorization: Bool = true,
        commandTimeoutSeconds: TimeInterval = 300
    ) {
        self.moleBinaryPath = moleBinaryPath
        self.supportURL = supportURL
        self.skipPrivilegedAuthorization = skipPrivilegedAuthorization
        self.commandTimeoutSeconds = commandTimeoutSeconds
    }
}

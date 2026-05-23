import Foundation

public final class MoleAdapter: @unchecked Sendable {
    public let executablePath: String
    public let workingDirectory: URL

    public init(executablePath: String, workingDirectory: URL? = nil) {
        self.executablePath = executablePath
        if let workingDirectory {
            self.workingDirectory = workingDirectory
        } else {
            self.workingDirectory = URL(fileURLWithPath: executablePath).deletingLastPathComponent()
        }
    }

    public func run(_ invocation: MoleInvocation) async -> CommandResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                continuation.resume(returning: self.runBlocking(invocation))
            }
        }
    }

    private func runBlocking(_ invocation: MoleInvocation) -> CommandResult {
        let started = Date()
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        let inputPipe = Pipe()
        let stdoutBuffer = LockedData()
        let stderrBuffer = LockedData()
        var timedOut = false

        process.executableURL = URL(fileURLWithPath: executablePath)
        process.arguments = invocation.arguments
        process.currentDirectoryURL = workingDirectory
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        process.standardInput = inputPipe
        process.environment = ProcessInfo.processInfo.environment.merging(invocation.environment) { _, new in new }

        stdoutPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                stdoutBuffer.append(data)
            }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty {
                stderrBuffer.append(data)
            }
        }

        let commandLine = ([executablePath] + invocation.arguments)
            .map(Self.shellQuoted)
            .joined(separator: " ")

        do {
            try process.run()
        } catch {
            let finished = Date()
            return CommandResult(
                commandLine: commandLine,
                arguments: invocation.arguments,
                startedAt: started,
                finishedAt: finished,
                exitCode: -1,
                stdout: "",
                stderr: "Unable to start Mole: \(error.localizedDescription)",
                timedOut: false
            )
        }

        if let standardInput = invocation.standardInput {
            inputPipe.fileHandleForWriting.write(Data(standardInput.utf8))
        }
        try? inputPipe.fileHandleForWriting.close()

        let timeoutTask = DispatchWorkItem {
            if process.isRunning {
                timedOut = true
                process.terminate()
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + invocation.timeoutSeconds, execute: timeoutTask)

        process.waitUntilExit()
        timeoutTask.cancel()

        stdoutPipe.fileHandleForReading.readabilityHandler = nil
        stderrPipe.fileHandleForReading.readabilityHandler = nil

        stdoutBuffer.append(stdoutPipe.fileHandleForReading.readDataToEndOfFile())
        stderrBuffer.append(stderrPipe.fileHandleForReading.readDataToEndOfFile())

        let finished = Date()
        let stdout = String(data: stdoutBuffer.data, encoding: .utf8) ?? ""
        let stderr = String(data: stderrBuffer.data, encoding: .utf8) ?? ""

        return CommandResult(
            commandLine: commandLine,
            arguments: invocation.arguments,
            startedAt: started,
            finishedAt: finished,
            exitCode: timedOut ? -9 : process.terminationStatus,
            stdout: stdout,
            stderr: stderr,
            timedOut: timedOut
        )
    }

    private static func shellQuoted(_ value: String) -> String {
        if value.range(of: #"[^A-Za-z0-9_@%+=:,./-]"#, options: .regularExpression) == nil {
            return value
        }
        return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}

private final class LockedData {
    private let lock = NSLock()
    private var storage = Data()

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ data: Data) {
        lock.lock()
        storage.append(data)
        lock.unlock()
    }
}

import EagleCore
import Foundation

enum AppDestination: Hashable {
    case dashboard
    case tool(MoleTool)
    case history
    case settings
}

@MainActor
final class AppModel: ObservableObject {
    @Published var destination: AppDestination? = .dashboard
    @Published var settings: AppSettings
    @Published var detectedMolePath: String = ""
    @Published var commandOutput: String = ""
    @Published var statusMessage: String = "Ready"
    @Published var isRunning = false
    @Published var reviewSession: ReviewSession?
    @Published var statusSnapshot: StatusSnapshot?
    @Published var analyzeReport: AnalyzeReport?
    @Published var history: [HistoryEntry] = []
    @Published var uninstallTarget: String = ""
    @Published var analyzePath: String = NSHomeDirectory()
    @Published var reviewAccepted = false

    private let settingsStore: SettingsStore
    private let historyStore: HistoryStore
    private let decoder = JSONDecoder()

    init(settingsStore: SettingsStore = SettingsStore(), historyStore: HistoryStore = HistoryStore()) {
        self.settingsStore = settingsStore
        self.historyStore = historyStore
        self.settings = settingsStore.load()
        self.detectedMolePath = MoleLocator.locate(preferredPath: settings.moleBinaryPath) ?? ""
        self.history = (try? historyStore.load()) ?? []
    }

    var activeMolePath: String {
        let configured = settings.moleBinaryPath.trimmingCharacters(in: .whitespacesAndNewlines)
        if MoleLocator.isExecutable(configured) {
            return configured
        }
        return detectedMolePath
    }

    var adapterReady: Bool {
        MoleLocator.isExecutable(activeMolePath)
    }

    var canExecuteReview: Bool {
        reviewAccepted && (reviewSession?.preview.succeeded == true) && !isRunning
    }

    func bootstrap() async {
        if adapterReady {
            await refreshStatus()
        } else {
            statusMessage = "Choose a Mole binary in Settings."
        }
    }

    func saveSettings() {
        settingsStore.save(settings)
        detectedMolePath = MoleLocator.locate(preferredPath: settings.moleBinaryPath) ?? ""
        statusMessage = adapterReady ? "Settings saved." : "Settings saved. Mole binary not found."
    }

    func autoDetectMole() {
        detectedMolePath = MoleLocator.locate() ?? ""
        settings.moleBinaryPath = detectedMolePath
        saveSettings()
    }

    func preview(_ tool: MoleTool) async {
        guard !isRunning else { return }
        reviewAccepted = false
        do {
            let invocation = try workflowFactory.previewInvocation(for: tool, target: target(for: tool))
            let result = await run(invocation, label: "Previewing \(tool.title)...")
            commandOutput = result.combinedOutput
            reviewSession = ReviewSession(tool: tool, target: target(for: tool), preview: result)
            statusMessage = result.succeeded ? "Preview ready. Review before running." : "Preview finished with warnings."
        } catch {
            show(error)
        }
    }

    func executeReview() async {
        guard let reviewSession, canExecuteReview else { return }

        do {
            let invocation = try workflowFactory.executeInvocation(
                for: reviewSession.tool,
                target: reviewSession.target
            )
            let result = await run(invocation, label: "Running \(reviewSession.tool.title)...")
            commandOutput = result.combinedOutput

            let entry = HistoryEntry(
                tool: reviewSession.tool,
                target: reviewSession.target,
                startedAt: result.startedAt,
                completedAt: result.finishedAt,
                previewExitCode: reviewSession.preview.exitCode,
                executionExitCode: result.exitCode,
                succeeded: result.succeeded,
                timedOut: result.timedOut,
                commandLine: result.commandLine,
                outputPreview: result.combinedOutput.condensedForReceipt()
            )
            history = (try? historyStore.append(entry)) ?? history
            statusMessage = result.succeeded ? "Finished. Receipt saved locally." : "Finished with errors. Receipt saved locally."
            self.reviewSession = nil
            reviewAccepted = false
        } catch {
            show(error)
        }
    }

    func refreshStatus() async {
        guard !isRunning else { return }
        let result = await run(workflowFactory.statusInvocation(), label: "Collecting status...")
        commandOutput = result.combinedOutput
        if let data = result.stdout.data(using: .utf8),
           let snapshot = try? decoder.decode(StatusSnapshot.self, from: data) {
            statusSnapshot = snapshot
            statusMessage = "Status refreshed."
        } else {
            statusMessage = "Status command ran, but JSON could not be decoded."
        }
    }

    func scanAnalyze() async {
        guard !isRunning else { return }
        let invocation = workflowFactory.analyzeInvocation(path: analyzePath)
        let result = await run(invocation, label: "Scanning disk usage...")
        commandOutput = result.combinedOutput
        if let data = result.stdout.data(using: .utf8),
           let report = try? decoder.decode(AnalyzeReport.self, from: data) {
            analyzeReport = report
            statusMessage = "Analyze scan complete."
        } else {
            statusMessage = "Analyze command ran, but JSON could not be decoded."
        }
    }

    func reloadHistory() {
        history = (try? historyStore.load()) ?? []
    }

    private var workflowFactory: MoleWorkflowFactory {
        MoleWorkflowFactory(
            skipPrivilegedAuthorization: settings.skipPrivilegedAuthorization,
            timeoutSeconds: settings.commandTimeoutSeconds
        )
    }

    private func target(for tool: MoleTool) -> String? {
        switch tool {
        case .uninstall:
            return uninstallTarget
        case .analyze:
            return analyzePath
        default:
            return nil
        }
    }

    private func run(_ invocation: MoleInvocation, label: String) async -> CommandResult {
        guard adapterReady else {
            let now = Date()
            let result = CommandResult(
                commandLine: "mole \(invocation.arguments.joined(separator: " "))",
                arguments: invocation.arguments,
                startedAt: now,
                finishedAt: now,
                exitCode: -1,
                stdout: "",
                stderr: "Mole binary not found. Open Settings and choose the repo's mole script or an installed mo binary."
            )
            commandOutput = result.combinedOutput
            statusMessage = "Mole binary not found."
            return result
        }

        isRunning = true
        statusMessage = label
        defer { isRunning = false }

        let adapter = MoleAdapter(executablePath: activeMolePath)
        return await adapter.run(invocation)
    }

    private func show(_ error: Error) {
        commandOutput = error.localizedDescription
        statusMessage = error.localizedDescription
    }
}

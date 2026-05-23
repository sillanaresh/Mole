import EagleCore
import Foundation

enum AppDestination: Hashable {
    case dashboard
    case tool(MoleTool)
    case history
    case settings
}

enum GuidedCleanupState: Equatable {
    case idle
    case scanning
    case ready
    case running
    case finished
}

struct GuidedCleanupItem: Identifiable, Equatable {
    var id: MoleTool { tool }
    let tool: MoleTool
    let title: String
    let summary: String
    let recommendation: String
    let defaultSelected: Bool
    let preview: CommandResult

    var previewSucceeded: Bool {
        preview.succeeded
    }

    var previewFoundNothing: Bool {
        let output = preview.combinedOutput.lowercased()
        return output.contains("great! no")
            || output.contains("no installer files to clean")
            || output.contains("no old project artifacts to clean")
            || (output.contains("no ") && output.contains("to clean"))
    }

    var statusText: String {
        if previewSucceeded {
            return recommendation
        }
        if previewFoundNothing {
            return "Nothing found"
        }
        return "Needs attention before running"
    }

    var previewIssueText: String? {
        guard !previewSucceeded else { return nil }

        if previewFoundNothing {
            return "Eagle did not find anything matching this cleanup right now, so there is nothing to run for this item."
        }

        if preview.timedOut {
            return "Preview timed out, so Eagle left this action off. Open raw command output for the command details."
        }

        let output = preview.combinedOutput
            .split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { !$0.isEmpty }

        if let output {
            return "Preview stopped with: \(output)"
        }

        return "Preview exited with code \(preview.exitCode), so Eagle left this action off."
    }
}

struct GuidedCleanupPlan: Equatable {
    var state: GuidedCleanupState
    var items: [GuidedCleanupItem]
    var scannedAt: Date
    var completedTools: [MoleTool]

    var readyItems: [GuidedCleanupItem] {
        items.filter(\.previewSucceeded)
    }
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
    @Published var guidedPlan: GuidedCleanupPlan?
    @Published var guidedSelectedTools: Set<MoleTool> = []
    @Published var guidedReviewPresented = false
    @Published var guidedAccepted = false
    @Published var guidedRunningTool: MoleTool?

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

    var canRunGuidedCleanup: Bool {
        guidedAccepted && !isRunning && guidedPlan?.state == .ready && !guidedSelectedItems.isEmpty
    }

    var guidedSelectedItems: [GuidedCleanupItem] {
        guard let guidedPlan else {
            return []
        }
        return guidedPlan.items.filter { guidedSelectedTools.contains($0.tool) && $0.previewSucceeded }
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

    func startGuidedScan() async {
        guard !isRunning else { return }

        guidedAccepted = false
        guidedRunningTool = nil
        guidedReviewPresented = false
        guidedSelectedTools = []
        guidedPlan = GuidedCleanupPlan(state: .scanning, items: [], scannedAt: Date(), completedTools: [])
        commandOutput = ""

        let statusResult = await run(workflowFactory.statusInvocation(), label: "Checking Mac health...")
        if let data = statusResult.stdout.data(using: .utf8),
           let snapshot = try? decoder.decode(StatusSnapshot.self, from: data) {
            statusSnapshot = snapshot
        }

        let analyzeResult = await run(workflowFactory.analyzeInvocation(path: NSHomeDirectory()), label: "Looking for large local folders...")
        if let data = analyzeResult.stdout.data(using: .utf8),
           let report = try? decoder.decode(AnalyzeReport.self, from: data) {
            analyzeReport = report
        }

        var items: [GuidedCleanupItem] = []
        for tool in Self.guidedCleanupTools {
            do {
                let invocation = try workflowFactory.previewInvocation(for: tool)
                let result = await run(invocation, label: "Previewing \(tool.title)...")
                items.append(Self.guidedItem(for: tool, preview: result))
            } catch {
                let now = Date()
                let result = CommandResult(
                    commandLine: "mole \(tool.rawValue) --dry-run",
                    arguments: [tool.rawValue, "--dry-run"],
                    startedAt: now,
                    finishedAt: now,
                    exitCode: -1,
                    stdout: "",
                    stderr: error.localizedDescription
                )
                items.append(Self.guidedItem(for: tool, preview: result))
            }
        }

        guidedSelectedTools = Set(items.filter { $0.defaultSelected && $0.previewSucceeded }.map(\.tool))
        guidedPlan = GuidedCleanupPlan(state: .ready, items: items, scannedAt: Date(), completedTools: [])
        commandOutput = Self.guidedTechnicalSummary(status: statusResult, analyze: analyzeResult, items: items)
        statusMessage = items.contains(where: \.previewSucceeded)
            ? "Simple scan ready. Review the cleanup plan."
            : "Simple scan finished, but no safe actions are ready."
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

    func executeGuidedCleanup() async {
        guard canRunGuidedCleanup, let guidedPlan else { return }

        let selectedItems = guidedSelectedItems
        guidedRunningTool = selectedItems.first?.tool
        self.guidedPlan = GuidedCleanupPlan(
            state: .running,
            items: guidedPlan.items,
            scannedAt: guidedPlan.scannedAt,
            completedTools: []
        )

        var completedTools: [MoleTool] = []
        var technicalOutput: [String] = []

        for item in selectedItems {
            guidedRunningTool = item.tool
            do {
                let invocation = try workflowFactory.executeInvocation(for: item.tool)
                let result = await run(invocation, label: "Running \(item.tool.title)...")
                technicalOutput.append("=== \(item.tool.title) ===")
                technicalOutput.append(result.combinedOutput)

                let entry = HistoryEntry(
                    tool: item.tool,
                    target: nil,
                    startedAt: result.startedAt,
                    completedAt: result.finishedAt,
                    previewExitCode: item.preview.exitCode,
                    executionExitCode: result.exitCode,
                    succeeded: result.succeeded,
                    timedOut: result.timedOut,
                    commandLine: result.commandLine,
                    outputPreview: result.combinedOutput.condensedForReceipt()
                )
                history = (try? historyStore.append(entry)) ?? history
                completedTools.append(item.tool)
            } catch {
                technicalOutput.append("=== \(item.tool.title) ===")
                technicalOutput.append(error.localizedDescription)
            }
        }

        self.guidedPlan = GuidedCleanupPlan(
            state: .finished,
            items: guidedPlan.items,
            scannedAt: guidedPlan.scannedAt,
            completedTools: completedTools
        )
        commandOutput = technicalOutput.joined(separator: "\n\n")
        statusMessage = completedTools.isEmpty
            ? "No selected cleanup actions ran."
            : "Simple cleanup finished. Receipt saved locally."
        guidedRunningTool = nil
        guidedAccepted = false
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

    private static let guidedCleanupTools: [MoleTool] = [.clean, .optimize, .purge, .installer]

    private static func guidedItem(for tool: MoleTool, preview: CommandResult) -> GuidedCleanupItem {
        switch tool {
        case .clean:
            return GuidedCleanupItem(
                tool: tool,
                title: "Everyday cleanup",
                summary: "Caches, logs, browser temporary files, and rebuildable developer clutter.",
                recommendation: "Suggested",
                defaultSelected: true,
                preview: preview
            )
        case .optimize:
            return GuidedCleanupItem(
                tool: tool,
                title: "Mac maintenance",
                summary: "Safe maintenance checks such as DNS, indexes, logs, and service refreshes.",
                recommendation: "Suggested",
                defaultSelected: true,
                preview: preview
            )
        case .purge:
            return GuidedCleanupItem(
                tool: tool,
                title: "Project cleanup",
                summary: "Build outputs and dependency folders inside development projects.",
                recommendation: "Optional, review first",
                defaultSelected: false,
                preview: preview
            )
        case .installer:
            return GuidedCleanupItem(
                tool: tool,
                title: "Installer cleanup",
                summary: "Old DMGs, PKGs, ZIPs, and duplicate installer downloads.",
                recommendation: "Optional, review first",
                defaultSelected: false,
                preview: preview
            )
        case .uninstall, .analyze, .status:
            return GuidedCleanupItem(
                tool: tool,
                title: tool.title,
                summary: tool.subtitle,
                recommendation: "Advanced tool",
                defaultSelected: false,
                preview: preview
            )
        }
    }

    private static func guidedTechnicalSummary(
        status: CommandResult,
        analyze: CommandResult,
        items: [GuidedCleanupItem]
    ) -> String {
        var sections = [
            "=== Mac health ===",
            status.combinedOutput,
            "=== Disk scan ===",
            analyze.combinedOutput
        ]

        for item in items {
            sections.append("=== \(item.title) preview ===")
            sections.append(item.preview.combinedOutput)
        }

        return sections.joined(separator: "\n\n")
    }
}

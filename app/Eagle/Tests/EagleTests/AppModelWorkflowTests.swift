import XCTest
@testable import Eagle
@testable import EagleCore

@MainActor
final class AppModelWorkflowTests: XCTestCase {
    func testReadOnlyToolsPopulateStatusAndAnalyzeResults() async throws {
        let harness = try AppHarness()
        let model = try harness.makeModel()

        await model.refreshStatus()
        XCTAssertEqual(model.statusSnapshot?.healthScore, 98)
        XCTAssertEqual(model.statusMessage, "Status refreshed.")
        XCTAssertTrue(model.commandOutput.contains("\"health_score\": 98"))

        model.analyzePath = harness.root.path
        await model.scanAnalyze()
        XCTAssertEqual(model.analyzeReport?.path, harness.root.path)
        XCTAssertEqual(model.analyzeReport?.entries.first?.name, "Caches")
        XCTAssertEqual(model.statusMessage, "Large-file scan complete.")

        let log = try harness.commandLog()
        XCTAssertTrue(log.contains("status --json|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("analyze --json \(harness.root.path)|dry=1|app=Eagle"))
    }

    func testEveryDestructiveToolPreviewsExecutesAndWritesReceipt() async throws {
        let harness = try AppHarness()
        let model = try harness.makeModel()

        let workflows: [(MoleTool, String?)] = [
            (.clean, nil),
            (.uninstall, "Example.app"),
            (.optimize, nil),
            (.purge, nil),
            (.installer, nil)
        ]

        for (tool, target) in workflows {
            model.uninstallTarget = target ?? ""

            await model.preview(tool)
            XCTAssertEqual(model.reviewSession?.tool, tool)
            XCTAssertEqual(model.reviewSession?.target, target)
            XCTAssertEqual(model.statusMessage, "Ready to review.")
            XCTAssertFalse(model.canExecuteReview)

            model.reviewAccepted = true
            XCTAssertTrue(model.canExecuteReview)

            await model.executeReview()
            XCTAssertNil(model.reviewSession)
            XCTAssertFalse(model.reviewAccepted)
            XCTAssertEqual(model.history.first?.tool, tool)
            XCTAssertEqual(model.history.first?.target, target)
            XCTAssertEqual(model.statusMessage, "Finished. History saved.")
        }

        XCTAssertEqual(model.history.map(\.tool), workflows.reversed().map(\.0))

        let log = try harness.commandLog()
        XCTAssertTrue(log.contains("clean --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("clean|dry=|app=Eagle"))
        XCTAssertTrue(log.contains("uninstall --dry-run Example.app|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("uninstall Example.app|dry=|app=Eagle"))
        XCTAssertTrue(log.contains("optimize --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("optimize|dry=|app=Eagle"))
        XCTAssertTrue(log.contains("purge --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("purge|dry=|app=Eagle"))
        XCTAssertTrue(log.contains("installer --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("installer|dry=|app=Eagle"))
    }

    func testGuidedCleanupScansDefaultsToSafeSelectionsAndRunsChosenTools() async throws {
        let harness = try AppHarness()
        let model = try harness.makeModel()

        await model.startGuidedScan()

        XCTAssertEqual(model.guidedPlan?.state, .ready)
        XCTAssertEqual(model.guidedPlan?.items.map(\.tool), [.clean, .optimize, .purge, .installer])
        XCTAssertEqual(model.statusSnapshot?.healthScore, 98)
        XCTAssertEqual(model.analyzeReport?.entries.first?.name, "Caches")
        XCTAssertEqual(model.guidedSelectedTools, Set([.clean, .optimize]))
        XCTAssertFalse(model.canRunGuidedCleanup)

        model.guidedSelectedTools.insert(.installer)
        model.guidedAccepted = true
        model.guidedReviewPresented = true
        XCTAssertTrue(model.canRunGuidedCleanup)

        await model.executeGuidedCleanup()

        XCTAssertEqual(model.guidedPlan?.state, .finished)
        XCTAssertEqual(model.guidedPlan?.completedTools, [.clean, .optimize, .installer])
        XCTAssertNil(model.guidedRunningTool)
        XCTAssertTrue(model.guidedReviewPresented)
        XCTAssertEqual(model.history.map(\.tool), [.installer, .optimize, .clean])
        XCTAssertEqual(model.statusMessage, "Simple cleanup finished. History saved.")

        let log = try harness.commandLog()
        XCTAssertTrue(log.contains("status --json|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("analyze --json \(NSHomeDirectory())|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("clean --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("optimize --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("purge --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("installer --dry-run|dry=1|app=Eagle"))
        XCTAssertTrue(log.contains("clean|dry=|app=Eagle"))
        XCTAssertTrue(log.contains("optimize|dry=|app=Eagle"))
        XCTAssertTrue(log.contains("installer|dry=|app=Eagle"))
    }

    func testGuidedCleanupExplainsNoOpPreviewWithoutCallingItRunnable() async throws {
        let harness = try AppHarness(mode: .projectAndInstallerEmpty)
        let model = try harness.makeModel()

        await model.startGuidedScan()

        let purge = try XCTUnwrap(model.guidedPlan?.items.first { $0.tool == .purge })
        let installer = try XCTUnwrap(model.guidedPlan?.items.first { $0.tool == .installer })

        XCTAssertFalse(purge.previewSucceeded)
        XCTAssertTrue(purge.previewFoundNothing)
        XCTAssertEqual(purge.statusText, "Nothing found")
        XCTAssertTrue(purge.previewIssueText?.contains("nothing to run") == true)
        XCTAssertFalse(installer.previewSucceeded)
        XCTAssertTrue(installer.previewFoundNothing)
        XCTAssertEqual(model.guidedSelectedTools, Set([.clean, .optimize]))
    }

    func testUninstallPreviewRequiresTargetAndDoesNotOpenReview() async throws {
        let harness = try AppHarness()
        let model = try harness.makeModel()

        model.uninstallTarget = "   "
        await model.preview(.uninstall)

        XCTAssertNil(model.reviewSession)
        XCTAssertEqual(model.statusMessage, "Uninstall needs a target before it can run.")
        XCTAssertTrue(model.commandOutput.contains("Uninstall needs a target"))
    }
}

private struct AppHarness {
    enum Mode {
        case normal
        case projectAndInstallerEmpty
    }

    let root: URL
    let executable: URL
    let log: URL
    let history: URL
    let mode: Mode

    init(mode: Mode = .normal) throws {
        self.mode = mode
        root = FileManager.default.temporaryDirectory
            .appendingPathComponent("EagleTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        executable = root.appendingPathComponent("mole")
        log = root.appendingPathComponent("commands.log")
        history = root.appendingPathComponent("history.json")
        try writeFakeMole()
    }

    @MainActor
    func makeModel() throws -> AppModel {
        let defaults = UserDefaults(suiteName: "EagleTests-\(UUID().uuidString)")!
        let settingsStore = SettingsStore(defaults: defaults)
        settingsStore.save(
            AppSettings(
                moleBinaryPath: executable.path,
                skipPrivilegedAuthorization: true,
                commandTimeoutSeconds: 5
            )
        )
        return AppModel(
            settingsStore: settingsStore,
            historyStore: HistoryStore(fileURL: history)
        )
    }

    func commandLog() throws -> String {
        try String(contentsOf: log, encoding: .utf8)
    }

    private func writeFakeMole() throws {
        let script = """
        #!/bin/sh
        printf '%s|dry=%s|app=%s\\n' "$*" "${MOLE_DRY_RUN:-}" "${MOLE_APP:-}" >> '\(log.path)'
        case "$1" in
          status)
            cat <<'JSON'
        {"health_score": 98, "uptime": "1 day", "cpu": {"usage": 12.5}, "memory": {"used_percent": 44.0}, "disks": [{"mount": "/", "total": 1000, "used_percent": 55.0}]}
        JSON
            ;;
          analyze)
            printf '{"path":"%s","overview":true,"entries":[{"name":"Caches","path":"%s/Caches","size":2048,"is_dir":true}],"total_size":2048,"total_files":1}\\n' "$3" "$3"
            ;;
          purge)
            if [ "\(mode)" = "projectAndInstallerEmpty" ]; then
              echo "Great! No old project artifacts to clean"
              exit 2
            fi
            echo "ok:$*"
            ;;
          installer)
            if [ "\(mode)" = "projectAndInstallerEmpty" ]; then
              echo "Great! No installer files to clean"
              exit 2
            fi
            echo "ok:$*"
            ;;
          *)
            echo "ok:$*"
            ;;
        esac
        """
        try script.write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)
    }
}

import XCTest
@testable import CheepuruKattaCore

final class HistoryStoreTests: XCTestCase {
    func testAppendPersistsNewestFirst() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = HistoryStore(fileURL: directory.appendingPathComponent("history.json"))

        let first = entry(tool: .clean)
        let second = entry(tool: .purge)

        _ = try store.append(first)
        let saved = try store.append(second)

        XCTAssertEqual(saved.map(\.tool), [.purge, .clean])
        XCTAssertEqual(try store.load().map(\.tool), [.purge, .clean])
    }

    func testAppendHonorsLimit() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let store = HistoryStore(fileURL: directory.appendingPathComponent("history.json"))

        _ = try store.append(entry(tool: .clean), limit: 1)
        let saved = try store.append(entry(tool: .installer), limit: 1)

        XCTAssertEqual(saved.count, 1)
        XCTAssertEqual(saved.first?.tool, .installer)
    }

    private func entry(tool: MoleTool) -> HistoryEntry {
        HistoryEntry(
            tool: tool,
            target: nil,
            startedAt: Date(),
            completedAt: Date(),
            previewExitCode: 0,
            executionExitCode: 0,
            succeeded: true,
            timedOut: false,
            commandLine: "mole \(tool.rawValue)",
            outputPreview: "done"
        )
    }
}

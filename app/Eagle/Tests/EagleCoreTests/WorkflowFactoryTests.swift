import XCTest
@testable import EagleCore

final class WorkflowFactoryTests: XCTestCase {
    func testCleanPreviewUsesDryRunAndNoAuth() throws {
        let factory = MoleWorkflowFactory(skipPrivilegedAuthorization: true, timeoutSeconds: 120)

        let invocation = try factory.previewInvocation(for: .clean)

        XCTAssertEqual(invocation.arguments, ["clean", "--dry-run"])
        XCTAssertEqual(invocation.environment["MOLE_DRY_RUN"], "1")
        XCTAssertEqual(invocation.environment["MOLE_TEST_NO_AUTH"], "1")
        XCTAssertEqual(invocation.environment["MOLE_DELETE_MODE"], "trash")
        XCTAssertEqual(invocation.timeoutSeconds, 120)
    }

    func testUninstallRequiresTarget() {
        let factory = MoleWorkflowFactory()

        XCTAssertThrowsError(try factory.previewInvocation(for: .uninstall)) { error in
            XCTAssertEqual(error as? MoleWorkflowError, .missingTarget(.uninstall))
        }
    }

    func testUninstallPreviewConfirmsDryRunOnly() throws {
        let factory = MoleWorkflowFactory()

        let invocation = try factory.previewInvocation(for: .uninstall, target: "Slack")

        XCTAssertEqual(invocation.arguments, ["uninstall", "--dry-run", "Slack"])
        XCTAssertEqual(invocation.standardInput, "y\n")
        XCTAssertEqual(invocation.environment["MOLE_DRY_RUN"], "1")
    }

    func testInstallerFlowSelectsAllForReviewDrivenRun() throws {
        let factory = MoleWorkflowFactory()

        let preview = try factory.previewInvocation(for: .installer)
        let execute = try factory.executeInvocation(for: .installer)

        XCTAssertEqual(preview.standardInput, "a\n\n")
        XCTAssertEqual(execute.standardInput, "a\n\n")
        XCTAssertEqual(preview.arguments, ["installer", "--dry-run"])
        XCTAssertEqual(execute.arguments, ["installer"])
    }

    func testStatusAndAnalyzeAreReadOnlyInvocations() {
        let factory = MoleWorkflowFactory()

        XCTAssertEqual(factory.statusInvocation().arguments, ["status", "--json"])
        XCTAssertEqual(factory.analyzeInvocation(path: "/tmp").arguments, ["analyze", "--json", "/tmp"])
    }
}

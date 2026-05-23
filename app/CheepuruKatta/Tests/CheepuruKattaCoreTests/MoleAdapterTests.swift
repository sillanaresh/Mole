import XCTest
@testable import CheepuruKattaCore

final class MoleAdapterTests: XCTestCase {
    func testAdapterRunsExecutableAndCapturesOutput() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appendingPathComponent("mole")
        try """
        #!/bin/sh
        echo "args:$*"
        echo "env:$MOLE_APP"
        exit 0
        """
        .write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        let adapter = MoleAdapter(executablePath: executable.path, workingDirectory: directory)
        let result = await adapter.run(
            MoleInvocation(
                arguments: ["status", "--json"],
                environment: ["MOLE_APP": "CheepuruKattaTest"],
                timeoutSeconds: 5
            )
        )

        XCTAssertTrue(result.succeeded)
        XCTAssertTrue(result.stdout.contains("args:status --json"))
        XCTAssertTrue(result.stdout.contains("env:CheepuruKattaTest"))
    }
}

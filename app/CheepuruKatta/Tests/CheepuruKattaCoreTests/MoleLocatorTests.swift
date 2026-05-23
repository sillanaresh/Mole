import XCTest
@testable import CheepuruKattaCore

final class MoleLocatorTests: XCTestCase {
    func testPreferredExecutableWins() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let executable = directory.appendingPathComponent("mole")
        try "#!/bin/sh\nexit 0\n".write(to: executable, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: executable.path)

        XCTAssertEqual(MoleLocator.locate(preferredPath: executable.path), executable.path)
    }

    func testNonExecutablePreferredPathIsIgnored() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let file = directory.appendingPathComponent("mole")
        try "not executable\n".write(to: file, atomically: true, encoding: .utf8)

        XCTAssertNotEqual(MoleLocator.locate(preferredPath: file.path, from: directory), file.path)
    }
}

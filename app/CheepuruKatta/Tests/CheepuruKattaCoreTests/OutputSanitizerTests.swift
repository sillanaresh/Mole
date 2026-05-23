import XCTest
@testable import CheepuruKattaCore

final class OutputSanitizerTests: XCTestCase {
    func testStripsANSISequences() {
        let raw = "\u{001B}[32mDone\u{001B}[0m"

        XCTAssertEqual(raw.strippingANSI(), "Done")
    }

    func testCondensesReceiptOutput() {
        let raw = " one \r\n two "

        XCTAssertEqual(raw.condensedForReceipt(), "one\ntwo")
    }

    func testReceiptOutputTruncates() {
        let raw = String(repeating: "a", count: 20)

        XCTAssertTrue(raw.condensedForReceipt(limit: 5).contains("Output truncated"))
    }
}

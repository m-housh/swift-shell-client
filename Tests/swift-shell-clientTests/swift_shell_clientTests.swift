import XCTest
@testable import swift_shell_client

final class swift_shell_clientTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(swift_shell_client().text, "Hello, World!")
    }
}

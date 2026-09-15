import XCTest
@testable import AttnDesignSystem

final class AttnDesignSystemTests: XCTestCase {
    func testFoundationConstants() {
        XCTAssertEqual(AttnSpacing.content, 16)
        XCTAssertEqual(AttnRadius.card, 28)
        XCTAssertEqual(AttnMotion.content, 0.300)
        XCTAssertEqual(AttnDesignSystem.version, "0.1.0")
    }
}

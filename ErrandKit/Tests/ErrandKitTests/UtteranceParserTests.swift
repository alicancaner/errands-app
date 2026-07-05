import XCTest
@testable import ErrandKit

final class UtteranceParserTests: XCTestCase {

    // Expected use
    func testSimpleFromClause() throws {
        let parsed = try UtteranceParser.parse("buy lentils from walmart")
        XCTAssertEqual(parsed.title, "buy lentils")
        XCTAssertEqual(parsed.storePhrases, ["walmart"])
    }

    func testMultipleStoresSplitOnOr() throws {
        let parsed = try UtteranceParser.parse("buy lentils from walmart or city market or aria")
        XCTAssertEqual(parsed.title, "buy lentils")
        XCTAssertEqual(parsed.storePhrases, ["walmart", "city market", "aria"])
    }

    func testMultipleStoresSplitOnAndAndCommas() throws {
        let parsed = try UtteranceParser.parse("buy lentils from walmart, city market and aria")
        XCTAssertEqual(parsed.title, "buy lentils")
        XCTAssertEqual(parsed.storePhrases, ["walmart", "city market", "aria"])
    }

    func testAtWorksLikeFrom() throws {
        let parsed = try UtteranceParser.parse("pick up prescription at walgreens")
        XCTAssertEqual(parsed.title, "pick up prescription")
        XCTAssertEqual(parsed.storePhrases, ["walgreens"])
    }

    // Edge cases
    func testNoStoreClauseGivesEmptyStores() throws {
        let parsed = try UtteranceParser.parse("buy lentils")
        XCTAssertEqual(parsed.title, "buy lentils")
        XCTAssertEqual(parsed.storePhrases, [String]())
    }

    func testArticlePreservedInStorePhrase() throws {
        let parsed = try UtteranceParser.parse("buy coffee from the persian market")
        XCTAssertEqual(parsed.title, "buy coffee")
        XCTAssertEqual(parsed.storePhrases, ["the persian market"])
    }

    func testOnlyLastFromClauseIsStoreClause() throws {
        let parsed = try UtteranceParser.parse("buy a walmart gift card from target")
        XCTAssertEqual(parsed.title, "buy a walmart gift card")
        XCTAssertEqual(parsed.storePhrases, ["target"])
    }

    // Store-clause splitting exposed for the "Where from?" follow-up answer
    func testStoreClauseSplitsOnOr() {
        XCTAssertEqual(
            UtteranceParser.storePhrases(fromClause: "walmart or city market"),
            ["walmart", "city market"]
        )
    }

    func testStoreClauseSplitsOnCommasAndAnd() {
        XCTAssertEqual(
            UtteranceParser.storePhrases(fromClause: "walmart, city market and aria"),
            ["walmart", "city market", "aria"]
        )
    }

    func testWhitespaceStoreClauseGivesNoPhrases() {
        XCTAssertEqual(UtteranceParser.storePhrases(fromClause: "   "), [String]())
    }

    // Failure case
    func testEmptyUtteranceThrows() {
        XCTAssertThrowsError(try UtteranceParser.parse("   ")) { error in
            XCTAssertEqual(error as? ParseError, ParseError.empty)
        }
        XCTAssertThrowsError(try UtteranceParser.parse("")) { error in
            XCTAssertEqual(error as? ParseError, ParseError.empty)
        }
    }
}

import XCTest
@testable import ErrandKit

final class SavedPlaceMatcherTests: XCTestCase {

    // Expected use — the Furfur's vet scenario from the design doc
    func testNicknameWordInPhraseMatches() {
        XCTAssertTrue(SavedPlaceMatcher.matches(
            nickname: "Furfur's vet", phrase: "his vet in yaletown"
        ))
    }

    func testWholeWordOnlyVetDoesNotMatchVelvet() {
        XCTAssertFalse(SavedPlaceMatcher.matches(
            nickname: "Furfur's vet", phrase: "buy velvet gloves"
        ))
    }

    func testCaseInsensitive() {
        XCTAssertTrue(SavedPlaceMatcher.matches(
            nickname: "ADIDAS Robson", phrase: "adidas"
        ))
    }

    func testShortNoiseWordsIgnored() {
        // "s" (from Furfur's) and "in" must never be match anchors.
        XCTAssertFalse(SavedPlaceMatcher.matches(
            nickname: "Furfur's vet", phrase: "s in the park"
        ))
    }

    func testMultiWordNicknameAnyWordMatches() {
        XCTAssertTrue(SavedPlaceMatcher.matches(
            nickname: "Yaletown Animal Hospital", phrase: "the animal hospital"
        ))
    }

    // Edge / failure cases
    func testEmptyPhraseNeverMatches() {
        XCTAssertFalse(SavedPlaceMatcher.matches(nickname: "Furfur's vet", phrase: ""))
    }

    func testNicknameWithNoSignificantWordsNeverMatches() {
        XCTAssertFalse(SavedPlaceMatcher.matches(nickname: "a b", phrase: "a b c"))
    }
}

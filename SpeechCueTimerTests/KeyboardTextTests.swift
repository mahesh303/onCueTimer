import XCTest
@testable import SpeechCueTimer

/// Capitalisation, the word being typed and suggestions for the floating keyboard.
final class KeyboardTextTests: XCTestCase {
    func testCapitalisesOnlyAtTheStartOfASentence() {
        XCTAssertTrue(KeyboardText.autoCapitalizes(""))
        XCTAssertFalse(KeyboardText.autoCapitalizes("Your"))
        // A space between words must not capitalise the next one ("Your Time Is Up").
        XCTAssertFalse(KeyboardText.autoCapitalizes("Your "))
        XCTAssertFalse(KeyboardText.autoCapitalizes("Your time is "))
        XCTAssertTrue(KeyboardText.autoCapitalizes("Time's up. "))
        XCTAssertTrue(KeyboardText.autoCapitalizes("Thank you!  "))
        XCTAssertTrue(KeyboardText.autoCapitalizes("Any questions? "))
        XCTAssertTrue(KeyboardText.autoCapitalizes("First line\n"))
        // Straight after the full stop, before the space, it's still the same sentence.
        XCTAssertFalse(KeyboardText.autoCapitalizes("Done."))
    }

    func testDeletingMidWordDoesNotCapitalise() {
        // "Yo" + typo, deleted: the next letter continues the word in lower case.
        var text = "Yox"
        text.removeLast()
        XCTAssertFalse(KeyboardText.autoCapitalizes(text))
        XCTAssertEqual(KeyboardText.currentWord(in: text), "Yo")
    }

    func testCurrentWord() {
        XCTAssertEqual(KeyboardText.currentWord(in: ""), "")
        XCTAssertEqual(KeyboardText.currentWord(in: "Your ti"), "ti")
        XCTAssertEqual(KeyboardText.currentWord(in: "Your "), "")
        XCTAssertEqual(KeyboardText.currentWord(in: "Line one\nwr"), "wr")
        XCTAssertEqual(KeyboardText.currentWord(in: "Wrap up."), "")
    }

    func testSuggestionsMatchCaseAndSkipTheTypedWord() {
        XCTAssertEqual(KeyboardText.suggestions(for: ""), [])
        let lower = KeyboardText.suggestions(for: "wr")
        XCTAssertTrue(lower.contains("wrap"))
        XCTAssertTrue(lower.allSatisfy { $0.hasPrefix("wr") })
        XCTAssertTrue(KeyboardText.suggestions(for: "Wr").contains("Wrap"))
        XCTAssertFalse(KeyboardText.suggestions(for: "time").contains("time"))
        XCTAssertLessThanOrEqual(KeyboardText.suggestions(for: "t").count, 3)
        let wh = KeyboardText.suggestions(for: "wh")
        XCTAssertEqual(wh.count, Set(wh).count, "No duplicates")
    }
}

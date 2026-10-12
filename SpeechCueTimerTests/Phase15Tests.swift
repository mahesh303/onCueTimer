import XCTest
@testable import SpeechCueTimer

/// Stop at zero, speaker background colours and the full emoji keyboard.
final class Phase15Tests: XCTestCase {
    var timerManager: TimerManager!

    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
    }

    override func tearDown() {
        timerManager?.pauseTimer()
        // Settings persist in UserDefaults; put the default back for other tests.
        timerManager?.settings.stopsAtZero = false
        timerManager = nil
        super.tearDown()
    }

    func testStopsAtZeroHoldsAtZero() {
        timerManager.settings.stopsAtZero = true
        timerManager.setTime(seconds: 1)
        timerManager.startTimer()

        let expectation = XCTestExpectation(description: "Timer stops at zero")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            XCTAssertEqual(self.timerManager.settings.remainingSeconds, 0)
            XCTAssertFalse(self.timerManager.settings.isRunning)
            XCTAssertEqual(self.timerManager.settings.timerState, .overtime)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testCountsIntoOvertimeByDefault() {
        XCTAssertFalse(timerManager.settings.stopsAtZero)
        timerManager.setTime(seconds: 1)
        timerManager.startTimer()

        let expectation = XCTestExpectation(description: "Timer counts past zero")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            XCTAssertLessThan(self.timerManager.settings.remainingSeconds, 0)
            XCTAssertTrue(self.timerManager.settings.isRunning)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
    }

    func testStopsAtZeroAfterSubtractingPastZero() {
        timerManager.settings.stopsAtZero = true
        timerManager.setTime(seconds: 30)
        timerManager.startTimer()
        timerManager.subtractTime(seconds: 60)

        let expectation = XCTestExpectation(description: "Timer clamps after subtract")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertEqual(self.timerManager.settings.remainingSeconds, 0)
            XCTAssertFalse(self.timerManager.settings.isRunning)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testBackgroundHexRoundTrip() {
        for preset in SpeakerBackground.presets {
            XCTAssertEqual(SpeakerBackground.hex(from: preset.color), preset.hex)
        }
        XCTAssertEqual(SpeakerBackground.hex(from: SpeakerBackground.color(fromHex: "not a colour")), "000000")
    }

    func testLightBackgroundWarning() {
        XCTAssertFalse(SpeakerBackground.isTooLightForWhiteText("000000"))
        XCTAssertTrue(SpeakerBackground.isTooLightForWhiteText("FFFFFF"))
        for preset in SpeakerBackground.presets {
            XCTAssertFalse(SpeakerBackground.isTooLightForWhiteText(preset.hex), preset.name)
        }
    }

    func testEmojiCatalogIsComplete() {
        let categories = EmojiCatalog.categories
        XCTAssertEqual(categories.count, 9)
        let total = categories.reduce(0) { $0 + $1.emoji.count }
        // ~1,900 in the list; anything the OS can't draw is dropped.
        XCTAssertGreaterThan(total, 1700)
        XCTAssertTrue(categories[0].emoji.contains("😀"))
        XCTAssertTrue(categories.last!.emoji.contains("🇺🇸"))
        XCTAssertTrue(categories.flatMap(\.emoji).contains("❤️‍🔥"))
    }
}

import XCTest

/// Takes the App Store screenshots. Skipped unless a folder is given, so it doesn't
/// slow down normal test runs:
///
///     TEST_RUNNER_SCREENSHOT_DIR=/path/to/folder xcodebuild test \
///         -only-testing:SpeechCueTimerUITests/AppStoreScreenshots ...
///
/// Run it on a 13-inch iPad simulator. Images are saved in portrait buffer order;
/// rotate them to landscape (for example `sips -r 270`) before uploading.
final class AppStoreScreenshots: XCTestCase {
    private var outputDirectory: String!
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        guard let directory = ProcessInfo.processInfo.environment["SCREENSHOT_DIR"] else {
            throw XCTSkip("Set TEST_RUNNER_SCREENSHOT_DIR to take App Store screenshots.")
        }
        outputDirectory = directory
        try FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    @MainActor
    func testGlassConsoleScreens() throws {
        launch(skin: "glassConsole")

        // 1. Running, with a message on the speaker display.
        setTime(minutes: 20, seconds: 0, opener: app.buttons["Set time"])
        let runningStart = startTimer()
        app.buttons["Message input"].firstMatch.tap()
        type("5 minutes left")
        tap("Done")
        tap("Send to display")
        waitForSettledDigits(after: runningStart, seconds: 13)
        save("01-running-message")

        // 2. Wrap-up warning.
        tap("Pause")
        tap("Clear")
        setTime(minutes: 1, seconds: 4, opener: app.buttons["Set time"])
        let wrapUpStart = startTimer()
        waitForSettledDigits(after: wrapUpStart, seconds: 7)
        save("02-wrap-up")

        // 3. Time's up: a waiting message goes up on its own and Zap glows.
        tap("Pause")
        tap("Clear")
        setTime(minutes: 0, seconds: 3, opener: app.buttons["Set time"])
        let timesUpStart = startTimer()
        app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", "Times up!")).firstMatch.tap()
        waitForSettledDigits(after: timesUpStart, seconds: 9)
        save("03-times-up")
        tap("Pause")

        // 5. Settings: skins and background colour.
        app.buttons["Settings"].firstMatch.tap()
        sleep(1)
        app.buttons["Navy"].firstMatch.tap()
        sleep(1)
        save("05-settings")
        app.buttons["Black"].firstMatch.tap()
        tap("Done")
    }

    @MainActor
    func testStageRingScreen() throws {
        launch(skin: "stageRing")

        // 4. Stage Ring, part-way through a talk.
        setTime(minutes: 1, seconds: 45, opener: app.buttons["Timer"].firstMatch)
        let ringStart = startTimer()
        waitForSettledDigits(after: ringStart, seconds: 14)
        save("04-stage-ring")
        tap("Pause")
    }

    // MARK: - Helpers

    private func launch(skin: String) {
        app = XCUIApplication()
        // Launch arguments set UserDefaults for this run only, and also stop the app
        // from changing them, so only pass ones the test never changes.
        app.launchArguments = ["-appSkin", skin, "-syncEnabled", "NO"]
        app.launch()
        sleep(2)
    }

    private func tap(_ label: String) {
        let button = app.buttons.matching(NSPredicate(format: "label BEGINSWITH[c] %@", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 3), "No button \(label)")
        button.tap()
    }

    private func startTimer() -> Date {
        tap("Start")
        return Date()
    }

    /// The digits roll to the next second with a short animation. Waiting until just
    /// after a tick keeps that blur out of the shot.
    private func waitForSettledDigits(after start: Date, seconds: Int) {
        let target = start.addingTimeInterval(Double(seconds) + 0.5)
        let wait = target.timeIntervalSinceNow
        if wait > 0 { usleep(useconds_t(wait * 1_000_000)) }
    }

    private func setTime(minutes: Int, seconds: Int, opener: XCUIElement) {
        opener.tap()
        let wheels = app.pickerWheels
        XCTAssertTrue(wheels.firstMatch.waitForExistence(timeout: 3))
        wheels.element(boundBy: 1).adjust(toPickerWheelValue: "\(minutes)")
        wheels.element(boundBy: 2).adjust(toPickerWheelValue: "\(seconds)")
        app.otherElements["PopoverDismissRegion"].firstMatch.tap()
        sleep(1)
    }

    /// Types on the app's own keyboard, one key at a time.
    private func type(_ text: String) {
        for character in text {
            let label = character == " " ? "Space" : String(character)
            app.buttons.matching(NSPredicate(format: "label ==[c] %@", label)).firstMatch.tap()
        }
    }

    private func save(_ name: String) {
        let data = XCUIScreen.main.screenshot().pngRepresentation
        try? data.write(to: URL(fileURLWithPath: "\(outputDirectory!)/\(name).png"))
    }
}

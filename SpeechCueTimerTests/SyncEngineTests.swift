import XCTest
@testable import SpeechCueTimer

/// Two (or three) devices wired straight to each other, no networking.
final class SyncEngineTests: XCTestCase {
    private final class Device {
        let timerManager = TimerManager()
        let fontSizeManager = FontSizeManager(scale: 1.0)
        lazy var displayManager = DisplayManager(timerManager: timerManager)
        lazy var engine = SyncEngine(timerManager: timerManager, displayManager: displayManager, fontSizeManager: fontSizeManager)
        let name: String

        init(_ name: String) {
            self.name = name
            _ = engine
        }
    }

    private var devices: [Device] = []

    override func tearDown() {
        for device in devices {
            device.timerManager.pauseTimer()
            device.timerManager.settings.stopsAtZero = false
        }
        devices = []
        UserDefaults.standard.set(60, forKey: "warningThresholdSeconds")
        super.tearDown()
    }

    private func makeDevice(_ name: String) -> Device {
        let device = Device(name)
        devices.append(device)
        return device
    }

    /// Connects every pair and delivers messages on the main queue, like SyncManager does.
    private func link(_ group: [Device]) {
        for device in group {
            device.engine.send = { data, peer in
                for other in group where other !== device && (peer == nil || peer == other.name) {
                    DispatchQueue.main.async { other.engine.receive(data, from: device.name) }
                }
            }
        }
        for device in group {
            for other in group where other !== device {
                device.engine.peerConnected(other.name)
            }
        }
    }

    /// Lets queued sends and observation callbacks run.
    private func settle(_ seconds: TimeInterval = 0.3) {
        let expectation = XCTestExpectation(description: "settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + seconds) { expectation.fulfill() }
        wait(for: [expectation], timeout: seconds + 1)
    }

    func testStartPauseAndMessageReachTheOtherDevice() {
        let a = makeDevice("A"), b = makeDevice("B")
        link([a, b])

        a.timerManager.setTime(seconds: 300)
        a.timerManager.startTimer()
        a.displayManager.message = "Wrap up"
        settle()

        XCTAssertTrue(b.timerManager.settings.isRunning)
        XCTAssertEqual(b.timerManager.settings.totalSeconds, 300)
        XCTAssertEqual(b.displayManager.message, "Wrap up")
        XCTAssertEqual(b.timerManager.targetDate!.timeIntervalSince(a.timerManager.targetDate!), 0, accuracy: 0.2)

        b.timerManager.pauseTimer()
        settle()

        XCTAssertFalse(a.timerManager.settings.isRunning)
        XCTAssertEqual(a.timerManager.settings.remainingSeconds, b.timerManager.settings.remainingSeconds)
    }

    func testAddTimeWhileRunningSyncs() {
        let a = makeDevice("A"), b = makeDevice("B")
        link([a, b])

        a.timerManager.setTime(seconds: 60)
        a.timerManager.startTimer()
        settle()
        b.timerManager.addTime(seconds: 60)
        settle()

        XCTAssertEqual(a.timerManager.targetDate!.timeIntervalSince(b.timerManager.targetDate!), 0, accuracy: 0.2)
        XCTAssertGreaterThan(a.timerManager.settings.remainingSeconds, 100)
    }

    func testSettingsSync() {
        let a = makeDevice("A"), b = makeDevice("B")
        link([a, b])

        a.timerManager.increaseWarningThreshold()
        a.timerManager.settings.stopsAtZero = true
        settle()

        XCTAssertEqual(b.timerManager.settings.warningThresholdSeconds, a.timerManager.settings.warningThresholdSeconds)
        XCTAssertTrue(b.timerManager.settings.stopsAtZero)
    }

    func testDeviceJoiningAdoptsTheRunningShow() {
        let a = makeDevice("A"), b = makeDevice("B")
        a.timerManager.setTime(seconds: 600)
        a.timerManager.startTimer()
        settle()

        // B was just launched and never touched; it must not reset A.
        link([a, b])
        settle()

        XCTAssertTrue(a.timerManager.settings.isRunning)
        XCTAssertTrue(b.timerManager.settings.isRunning)
        XCTAssertEqual(b.timerManager.settings.totalSeconds, 600)
    }

    func testMostRecentChangeWinsOnJoin() {
        let a = makeDevice("A"), b = makeDevice("B")
        a.timerManager.setTime(seconds: 120)
        settle(0.1)
        b.timerManager.setTime(seconds: 900)
        settle(0.1)

        link([a, b])
        settle()

        XCTAssertEqual(a.timerManager.settings.totalSeconds, 900)
        XCTAssertEqual(b.timerManager.settings.totalSeconds, 900)
    }

    func testThreeDevicesStayInStep() {
        let a = makeDevice("A"), b = makeDevice("B"), c = makeDevice("C")
        link([a, b, c])

        c.timerManager.setTime(seconds: 45)
        c.timerManager.startTimer()
        settle()

        XCTAssertTrue(a.timerManager.settings.isRunning)
        XCTAssertTrue(b.timerManager.settings.isRunning)
        XCTAssertEqual(a.timerManager.settings.remainingSeconds, c.timerManager.settings.remainingSeconds)
    }

    func testClockDifferenceIsCorrected() throws {
        let b = makeDevice("B")
        // A's clock runs 30 s ahead of B's. Its timer ends 60 s from now (in true time).
        let skew: TimeInterval = 30
        let state = SyncState(
            totalSeconds: 120, remainingSeconds: 0,
            endDate: Date().addingTimeInterval(60 + skew),
            warningThresholdSeconds: 60, pulseAnimationEnabled: true, stopsAtZero: false, message: "",
            timePresets: [:], savedMessages: [nil, nil, nil, nil], fontScale: 1.0
        )
        let envelope = SyncEnvelope(sentAt: Date().addingTimeInterval(skew), payload: .state(state, changedAt: Date().addingTimeInterval(skew)))
        b.engine.receive(try JSONEncoder().encode(envelope), from: "A")

        XCTAssertTrue(b.timerManager.settings.isRunning)
        XCTAssertEqual(b.timerManager.targetDate!.timeIntervalSinceNow, 60, accuracy: 0.5)
    }

    func testReceivedZapShakesWithoutEcho() throws {
        let b = makeDevice("B")
        var sentByB = 0
        b.engine.send = { _, _ in sentByB += 1 }

        // Every engine in this process hears every zap, so feed B one directly.
        // Match the marker by value: matching on `object:` compares identity, which
        // iPadOS 18 doesn't preserve for bridged strings.
        let zapped = expectation(forNotification: .messageZap, object: nil) { notification in
            (notification.object as? String) == SyncEngine.remoteZapMarker
        }
        let envelope = SyncEnvelope(sentAt: Date(), payload: .zap)
        b.engine.receive(try JSONEncoder().encode(envelope), from: "A")
        wait(for: [zapped], timeout: 1)

        XCTAssertEqual(sentByB, 0)
    }

    func testPresetsSync() {
        let a = makeDevice("A"), b = makeDevice("B")
        link([a, b])

        a.timerManager.setTime(seconds: 420)
        a.timerManager.savePreset(number: 2)
        a.displayManager.savedMessages[1] = "Two minutes"
        settle()

        XCTAssertEqual(b.timerManager.settings.presets[2], 420)
        XCTAssertEqual(b.displayManager.savedMessages[1], "Two minutes")
        XCTAssertEqual(b.displayManager.savedMessages[0], "Times up!")
    }

    func testTextSizeSyncs() {
        let a = makeDevice("A"), b = makeDevice("B")
        link([a, b])

        a.fontSizeManager.increaseFontSize()
        a.fontSizeManager.increaseFontSize()
        settle()
        XCTAssertEqual(b.fontSizeManager.currentScale, 1.2, accuracy: 0.001)

        b.fontSizeManager.decreaseFontSize()
        settle()
        XCTAssertEqual(a.fontSizeManager.currentScale, 1.1, accuracy: 0.001)
    }
}

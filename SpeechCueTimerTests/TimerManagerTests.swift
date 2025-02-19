import XCTest
@testable import SpeechCueTimer

final class TimerManagerTests: XCTestCase {
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
    }
    
    override func tearDown() {
        timerManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(timerManager.settings.remainingSeconds, 0)
        XCTAssertEqual(timerManager.settings.totalSeconds, 0)
        XCTAssertFalse(timerManager.settings.isRunning)
        XCTAssertEqual(timerManager.settings.timerState, .ready)
    }
    
    func testSetTime() {
        // Test setting time in minutes
        timerManager.setTime(minutes: 5)
        XCTAssertEqual(timerManager.settings.totalSeconds, 300)
        XCTAssertEqual(timerManager.settings.remainingSeconds, 300)
        
        // Test setting time in seconds
        timerManager.setTime(seconds: 30)
        XCTAssertEqual(timerManager.settings.totalSeconds, 30)
        XCTAssertEqual(timerManager.settings.remainingSeconds, 30)
    }
    
    func testTimerControls() {
        timerManager.setTime(minutes: 1)
        
        // Test start
        timerManager.startTimer()
        XCTAssertTrue(timerManager.settings.isRunning)
        XCTAssertEqual(timerManager.settings.timerState, .running)
        
        // Test pause
        timerManager.pauseTimer()
        XCTAssertFalse(timerManager.settings.isRunning)
        XCTAssertEqual(timerManager.settings.timerState, .ready)
        
        // Test clear
        timerManager.setTime(seconds: 0)
        XCTAssertEqual(timerManager.settings.remainingSeconds, 0)
        XCTAssertEqual(timerManager.settings.timerState, .completed)
    }
    
    func testPresetManagement() {
        // Save preset
        timerManager.setTime(minutes: 5)
        timerManager.savePreset(number: 1)
        XCTAssertEqual(timerManager.settings.presets[1], 300)
        
        // Load preset
        timerManager.setTime(seconds: 0)
        timerManager.loadPreset(number: 1)
        XCTAssertEqual(timerManager.settings.totalSeconds, 300)
        
        // Test preset time string
        XCTAssertEqual(timerManager.getPresetTimeString(number: 1), "05:00")
    }
    
    func testTimeAdjustment() {
        timerManager.setTime(minutes: 1)
        
        // Test add time
        timerManager.addTime(seconds: 10)
        XCTAssertEqual(timerManager.settings.remainingSeconds, 70)
        
        // Test subtract time
        timerManager.subtractTime(seconds: 30)
        XCTAssertEqual(timerManager.settings.remainingSeconds, 40)
        
        // Test subtract below zero
        timerManager.subtractTime(seconds: 50)
        XCTAssertEqual(timerManager.settings.remainingSeconds, 0)
    }
    
    func testRepeatLastTimer() {
        timerManager.setTime(minutes: 2)
        timerManager.startTimer()
        timerManager.pauseTimer()
        
        timerManager.setTime(seconds: 0)
        timerManager.repeatLastTimer()
        XCTAssertEqual(timerManager.settings.totalSeconds, 120)
    }
} 
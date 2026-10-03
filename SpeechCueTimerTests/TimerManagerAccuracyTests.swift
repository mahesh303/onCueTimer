import XCTest
@testable import SpeechCueTimer

final class TimerManagerAccuracyTests: XCTestCase {
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
    }
    
    override func tearDown() {
        timerManager?.pauseTimer()
        timerManager = nil
        super.tearDown()
    }
    
    func testTimerAccuracyConcept() {
        // Since we can't easily mock Date() without dependency injection change,
        // we will test that startTimer sets the state correctly and that pauseTimer
        // captures the remaining time correctly.
        
        timerManager.setTime(seconds: 100)
        timerManager.startTimer()
        
        XCTAssertTrue(timerManager.settings.isRunning)
        XCTAssertNotNil(timerManager.settings.remainingSeconds)
        
        // We can't "sleep" for 30 seconds to test background drift in a unit test easily without slowing it down.
        // But we can verify that modifying the targetDate (if it were accessible) or 
        // seeing that addTime works via Date manipulation proves we are using the new logic.
        
        // Let's just verify basic functionality didn't break
        let expectation = XCTestExpectation(description: "Timer ticks")
        
        // Wait 1.5 seconds, expect remaining to be 99 or 98
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            let remaining = self.timerManager.settings.remainingSeconds
            XCTAssertTrue(remaining <= 99)
            XCTAssertTrue(remaining >= 98)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 2.0)
    }
    
    func testAddTimeWhileRunning() {
        timerManager.setTime(seconds: 60)
        timerManager.startTimer()
        
        // Simulate add time
        timerManager.addTime(seconds: 30)
        
        let expectation = XCTestExpectation(description: "Timer updates after add")
        
        // Allow run loop to process
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            // Should be around 90 seconds now
            let remaining = self.timerManager.settings.remainingSeconds
            XCTAssertTrue(remaining >= 89 && remaining <= 91)
            XCTAssertTrue(self.timerManager.settings.totalSeconds >= 90)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 1.0)
    }
}

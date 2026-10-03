import XCTest
@testable import SpeechCueTimer

final class ContentViewModelTests: XCTestCase {
    var viewModel: ContentViewModel!
    var timerManager: TimerManager!
    
    override func setUp() {
        super.setUp()
        timerManager = TimerManager()
        viewModel = ContentViewModel(timerManager: timerManager)
    }
    
    override func tearDown() {
        viewModel = nil
        timerManager = nil
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "messagePresets")
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(viewModel.message, "")
        XCTAssertEqual(viewModel.displayMessage, "")
        XCTAssertFalse(viewModel.isTimerRunning)
        XCTAssertEqual(viewModel.presets.count, 4)
        XCTAssertEqual(viewModel.presets[0], "Times up!") // Preset 1 has default message
        XCTAssertNil(viewModel.presets[1]) // Other presets are nil
        XCTAssertNil(viewModel.presets[2])
        XCTAssertNil(viewModel.presets[3])
    }
    
    func testTimerControls() {
        // Test start timer
        viewModel.startTimer()
        XCTAssertTrue(viewModel.isTimerRunning)
        XCTAssertTrue(timerManager.settings.isRunning)
        XCTAssertEqual(viewModel.displayMessage, "")
        
        // Test pause timer
        viewModel.pauseTimer()
        XCTAssertFalse(viewModel.isTimerRunning)
        XCTAssertFalse(timerManager.settings.isRunning)
        
        // Test clear timer
        timerManager.setTime(minutes: 1)
        viewModel.clearTimer()
        XCTAssertEqual(timerManager.settings.remainingSeconds, 0)
    }
    
    func testMessageHandling() {
        // Test send message
        viewModel.message = "Test Message"
        viewModel.sendMessage()
        XCTAssertEqual(viewModel.displayMessage, "Test Message")
        
        // Test clear message
        viewModel.clearMessage()
        XCTAssertEqual(viewModel.message, "")
        XCTAssertEqual(viewModel.displayMessage, "")
    }
    
    func testPresetManagement() {
        // Test save preset
        viewModel.message = "Preset 1 Message"
        viewModel.savePreset(at: 0)
        XCTAssertEqual(viewModel.presets[0], "Preset 1 Message")
        
        // Test load preset
        viewModel.message = ""
        viewModel.loadPreset(at: 0)
        XCTAssertEqual(viewModel.message, "Preset 1 Message")
        
        // Test preset persistence
        let savedPresets = UserDefaults.standard.array(forKey: "messagePresets") as? [String?]
        XCTAssertNotNil(savedPresets)
        XCTAssertEqual(savedPresets?[0], "Preset 1 Message")
    }
    
    func testSendPresetKeepsDraft() {
        viewModel.message = "Draft in progress"
        viewModel.sendPreset(at: 0)
        XCTAssertEqual(viewModel.displayMessage, "Times up!")
        XCTAssertEqual(viewModel.message, "Draft in progress")

        // Empty slots and out-of-range indexes leave the display alone
        viewModel.sendPreset(at: 1)
        viewModel.sendPreset(at: 9)
        XCTAssertEqual(viewModel.displayMessage, "Times up!")
    }

    func testHideMessageKeepsDraft() {
        viewModel.message = "Wrap up"
        viewModel.sendMessage()
        viewModel.message = "Next draft"

        viewModel.hideMessage()
        XCTAssertEqual(viewModel.displayMessage, "")
        XCTAssertEqual(viewModel.message, "Next draft")
    }

    func testDefaultPreset() {
        // Test that preset 1 loads the default message
        viewModel.loadPreset(at: 0)
        XCTAssertEqual(viewModel.message, "Times up!")
        
        // Test that other presets don't load anything when empty
        viewModel.message = "some text"
        viewModel.loadPreset(at: 1) // Should not change message since preset 2 is nil
        XCTAssertEqual(viewModel.message, "some text")
    }
    
    func testPresetPersistence() {
        // Save some presets
        let testPresets: [String?] = ["Test 1", nil, "Test 3", nil]
        UserDefaults.standard.set(testPresets, forKey: "messagePresets")
        
        // Create new view model to test loading
        let newViewModel = ContentViewModel(timerManager: timerManager)
        XCTAssertEqual(newViewModel.presets[0], "Times up!") // Should still have default
        XCTAssertNil(newViewModel.presets[1])
        XCTAssertNil(newViewModel.presets[2])
        XCTAssertNil(newViewModel.presets[3])
    }
} 
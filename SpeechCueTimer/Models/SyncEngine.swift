//
//  SyncEngine.swift
//  SpeechCueTimer
//
//  Keeps the timer, the on-screen message and the timer settings the same on every
//  iPad in a show. Every device is equal: whichever one changed something last wins.
//  The transport (MultipeerConnectivity, see SyncManager) only moves bytes, so this
//  logic can be tested with two engines wired straight to each other.
//

import Foundation
import Observation

/// Everything that is shared between devices. Skin and background colour stay
/// per device, since each iPad drives its own screen.
/// Both iPads need the same app version: a state from a different shape is ignored.
struct SyncState: Codable, Equatable {
    var totalSeconds: Int
    /// Only meaningful while stopped; a running timer is described by `endDate`.
    var remainingSeconds: Int
    /// When the running countdown hits zero, in the sender's clock. Nil when stopped.
    var endDate: Date?
    var warningThresholdSeconds: Int
    var pulseAnimationEnabled: Bool
    var stopsAtZero: Bool
    var message: String
    /// Quick-time slots: slot number → seconds.
    var timePresets: [Int: Int]
    var savedMessages: [String?]
    /// Speaker-display text size (A− / A+), 0.5 ... 2.0.
    var fontScale: Double
}

struct SyncEnvelope: Codable {
    enum Payload: Codable {
        /// `changedAt` is nil when the sender has never been touched since launch,
        /// so a fresh device joining a show adopts the show instead of resetting it.
        case state(SyncState, changedAt: Date?)
        case zap
        /// Heartbeat that keeps the clock-offset estimate fresh.
        case ping
    }

    /// Sender's clock at send time, used to estimate the clock difference between devices.
    var sentAt: Date
    var payload: Payload
}

/// Used only on the main queue: SyncManager hops there before calling in, and
/// observation callbacks are bounced there too.
final class SyncEngine: @unchecked Sendable {
    /// Marks `.messageZap` notifications that came from another device, so they aren't sent back.
    static let remoteZapMarker = "SyncEngine.remoteZap"

    /// Sends encoded data to one peer, or to every peer when the key is nil.
    var send: (Data, _ peer: String?) -> Void = { _, _ in }

    private let timerManager: TimerManager
    private let displayManager: DisplayManager
    private let fontSizeManager: FontSizeManager

    /// Last state this device showed, whether changed here or received.
    private var lastState: SyncState?
    /// When the shared state last changed, in this device's clock. Nil until something changes.
    private(set) var changedAt: Date?
    private var isApplyingRemote = false
    /// Recent (sender clock − local clock − latency) samples per peer.
    private var offsetSamples: [String: [TimeInterval]] = [:]
    private var zapObserver: (any NSObjectProtocol)?

    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(timerManager: TimerManager, displayManager: DisplayManager, fontSizeManager: FontSizeManager = .shared) {
        self.timerManager = timerManager
        self.displayManager = displayManager
        self.fontSizeManager = fontSizeManager
        lastState = currentState()
        track()

        zapObserver = NotificationCenter.default.addObserver(forName: .messageZap, object: nil, queue: .main) { [weak self] notification in
            guard (notification.object as? String) != Self.remoteZapMarker else { return }
            self?.sendEnvelope(.zap, to: nil)
        }
    }

    deinit {
        if let zapObserver {
            NotificationCenter.default.removeObserver(zapObserver)
        }
    }

    func currentState() -> SyncState {
        let settings = timerManager.settings
        let isRunning = settings.isRunning
        return SyncState(
            totalSeconds: settings.totalSeconds,
            remainingSeconds: isRunning ? 0 : settings.remainingSeconds,
            endDate: isRunning ? timerManager.targetDate : nil,
            warningThresholdSeconds: settings.warningThresholdSeconds,
            pulseAnimationEnabled: settings.pulseAnimationEnabled,
            stopsAtZero: settings.stopsAtZero,
            message: displayManager.message,
            timePresets: settings.presets,
            savedMessages: displayManager.savedMessages,
            fontScale: fontSizeManager.currentScale
        )
    }

    // MARK: - Local changes

    /// Watches everything in `SyncState`. The per-second tick only touches
    /// `remainingSeconds` while running, which isn't read then, so ticks aren't sent.
    private func track() {
        withObservationTracking {
            _ = currentState()
        } onChange: { [weak self] in
            // onChange runs before the new value is stored; read it on the next turn.
            DispatchQueue.main.async {
                self?.stateDidChange()
                self?.track()
            }
        }
    }

    private func stateDidChange() {
        let state = currentState()
        // Applying a received state also lands here; it already matches lastState.
        guard state != lastState, !isApplyingRemote else { return }
        lastState = state
        changedAt = Date()
        sendEnvelope(.state(state, changedAt: changedAt), to: nil)
    }

    // MARK: - Peers

    /// A device just joined: tell it what this device shows. If it has changed
    /// something more recently, its own state will win on both sides.
    func peerConnected(_ peer: String) {
        sendEnvelope(.state(currentState(), changedAt: changedAt), to: peer)
    }

    func peerDisconnected(_ peer: String) {
        offsetSamples[peer] = nil
    }

    func sendPing() {
        sendEnvelope(.ping, to: nil)
    }

    func receive(_ data: Data, from peer: String) {
        guard let envelope = try? decoder.decode(SyncEnvelope.self, from: data) else { return }
        let offset = recordOffset(envelope.sentAt, from: peer)

        switch envelope.payload {
        case .ping:
            break
        case .zap:
            NotificationCenter.default.post(name: .messageZap, object: Self.remoteZapMarker)
        case let .state(state, changedAt: remoteChangedAt):
            guard let remoteChangedAt else { return }
            let localChangedAt = remoteChangedAt.addingTimeInterval(-offset)
            if let changedAt, localChangedAt <= changedAt { return }
            apply(state, clockOffset: offset)
            changedAt = localChangedAt
        }
    }

    /// Best estimate of how far the peer's clock is ahead of ours. Each sample is the
    /// true offset minus network latency, so the largest recent sample is the closest.
    private func recordOffset(_ sentAt: Date, from peer: String) -> TimeInterval {
        var samples = offsetSamples[peer, default: []]
        samples.append(sentAt.timeIntervalSince(Date()))
        if samples.count > 10 { samples.removeFirst(samples.count - 10) }
        offsetSamples[peer] = samples
        return samples.max() ?? 0
    }

    private func apply(_ state: SyncState, clockOffset: TimeInterval) {
        isApplyingRemote = true
        defer { isApplyingRemote = false }

        timerManager.applySyncedState(state, endDate: state.endDate?.addingTimeInterval(-clockOffset))
        displayManager.message = state.message
        displayManager.savedMessages = state.savedMessages
        if fontSizeManager.currentScale != state.fontScale {
            fontSizeManager.currentScale = state.fontScale
        }
        lastState = currentState()
    }

    private func sendEnvelope(_ payload: SyncEnvelope.Payload, to peer: String?) {
        guard let data = try? encoder.encode(SyncEnvelope(sentAt: Date(), payload: payload)) else { return }
        send(data, peer)
    }
}

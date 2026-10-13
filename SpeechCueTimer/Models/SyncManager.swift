//
//  SyncManager.swift
//  SpeechCueTimer
//
//  Finds other iPads using the same show code and connects them with
//  MultipeerConnectivity (Wi-Fi, peer-to-peer Wi-Fi or Bluetooth; no router needed).
//  What gets shared, and how conflicts resolve, lives in SyncEngine.
//

import MultipeerConnectivity
import Observation
import UIKit

@Observable final class SyncManager: NSObject {
    static let serviceType = "oncue-sync"   // must match NSBonjourServices in SpeechCueTimer-Info.plist
    static let codeLength = 4

    var isEnabled: Bool {
        didSet {
            guard isEnabled != oldValue else { return }
            UserDefaults.standard.set(isEnabled, forKey: "syncEnabled")
            isEnabled ? start() : stop()
        }
    }

    /// Only devices with the same code connect, so two shows in one venue stay apart.
    var showCode: String {
        didSet {
            guard showCode != oldValue else { return }
            UserDefaults.standard.set(showCode, forKey: "syncShowCode")
            restartIfEnabled()
        }
    }

    /// Shown on the other iPads. iOS reports every iPad as just "iPad", so it's editable.
    var deviceName: String {
        didSet {
            guard deviceName != oldValue else { return }
            UserDefaults.standard.set(deviceName, forKey: "syncDeviceName")
            restartIfEnabled()
        }
    }

    private(set) var connectedPeerNames: [String] = []

    @ObservationIgnored let engine: SyncEngine
    @ObservationIgnored private var session: MCSession?
    @ObservationIgnored private var advertiser: MCNearbyServiceAdvertiser?
    @ObservationIgnored private var browser: MCNearbyServiceBrowser?
    @ObservationIgnored private var heartbeat: Timer?
    /// Permanent per install. Lets devices recognise each other across reconnects,
    /// refuse to link to themselves, and decide which side sends the invitation.
    @ObservationIgnored private let deviceID: String
    /// Device ID of every peer we've seen, learned from discovery info or the invitation.
    @ObservationIgnored private var peerDevices: [MCPeerID: String] = [:]
    /// Devices we've invited and are waiting on, so the browser doesn't invite twice.
    @ObservationIgnored private var invitedDevices: Set<String> = []
    /// Peers the browser can currently see; a failed invitation is retried while they stay.
    @ObservationIgnored private var nearbyPeers: Set<MCPeerID> = []

    init(engine: SyncEngine) {
        self.engine = engine
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: "syncEnabled")
        showCode = defaults.string(forKey: "syncShowCode") ?? Self.randomCode()
        deviceName = defaults.string(forKey: "syncDeviceName") ?? UIDevice.current.name
        if let saved = defaults.string(forKey: "syncDeviceID") {
            deviceID = saved
        } else {
            deviceID = UUID().uuidString
            defaults.set(deviceID, forKey: "syncDeviceID")
        }
        super.init()

        defaults.set(showCode, forKey: "syncShowCode")
        engine.send = { [weak self] data, peer in self?.send(data, to: peer) }

        // Background/foreground rather than resign/become active, which also fire
        // for alerts, Control Center and the app switcher.
        NotificationCenter.default.addObserver(self, selector: #selector(appDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(appWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)

        if isEnabled {
            start()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stop()
    }

    static func randomCode() -> String {
        String(format: "%04d", Int.random(in: 0...9999))
    }

    // MARK: - Lifecycle

    private func start() {
        stop()

        let peerID = makePeerID()
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["code": showCode, "id": deviceID],
            serviceType: Self.serviceType
        )
        advertiser.delegate = self

        let browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser.delegate = self

        self.session = session
        self.advertiser = advertiser
        self.browser = browser
        advertiser.startAdvertisingPeer()
        browser.startBrowsingForPeers()

        heartbeat = Timer.scheduledTimer(withTimeInterval: 2, repeats: true) { [weak self] _ in
            guard let self, !self.connectedPeerNames.isEmpty else { return }
            self.engine.sendPing()
        }
    }

    private func stop() {
        heartbeat?.invalidate()
        heartbeat = nil
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session?.disconnect()
        advertiser = nil
        browser = nil
        session = nil
        peerDevices = [:]
        invitedDevices = []
        nearbyPeers = []
        connectedPeerNames = []
    }

    private func restartIfEnabled() {
        if isEnabled { start() }
    }

    /// iOS tears peer connections down in the background anyway; leaving cleanly
    /// lets the other iPads drop this one straight away instead of keeping a ghost.
    @objc private func appDidEnterBackground() {
        if isEnabled { stop() }
    }

    @objc private func appWillEnterForeground() {
        if isEnabled { start() }
    }

    /// Reuses the same MCPeerID across restarts (Apple's advice): a fresh one each
    /// time leaves the other devices holding stale entries for the old one.
    private func makePeerID() -> MCPeerID {
        let name = Self.peerDisplayName(deviceName)
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: "syncPeerID"),
           let saved = try? NSKeyedUnarchiver.unarchivedObject(ofClass: MCPeerID.self, from: data),
           saved.displayName == name {
            return saved
        }
        let peerID = MCPeerID(displayName: name)
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: peerID, requiringSecureCoding: true) {
            defaults.set(data, forKey: "syncPeerID")
        }
        return peerID
    }

    // MARK: - Sending

    private func send(_ data: Data, to peerKey: String?) {
        guard let session, !session.connectedPeers.isEmpty else { return }
        let peers = peerKey.map { key in session.connectedPeers.filter { Self.key(for: $0) == key } } ?? session.connectedPeers
        guard !peers.isEmpty else { return }
        try? session.send(data, toPeers: peers, with: .reliable)
    }

    private static func key(for peer: MCPeerID) -> String {
        String(peer.hash)
    }

    /// MCPeerID names are limited to 63 bytes of UTF-8.
    private static func peerDisplayName(_ name: String) -> String {
        var trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { trimmed = "iPad" }
        while trimmed.utf8.count > 63 { trimmed.removeLast() }
        return trimmed
    }

    /// One entry per device, even if it briefly has two connections while reconnecting.
    private func refreshPeers() {
        var seen = Set<String>()
        connectedPeerNames = (session?.connectedPeers ?? [])
            .filter { seen.insert(peerDevices[$0] ?? Self.key(for: $0)).inserted }
            .map(\.displayName)
            .sorted()
    }

    private func isConnected(toDevice id: String) -> Bool {
        (session?.connectedPeers ?? []).contains { peerDevices[$0] == id }
    }

    /// Invitation context: the show code and the inviter's device ID.
    private func invitationContext() -> Data {
        Data("\(showCode)\n\(deviceID)".utf8)
    }
}

// MARK: - MultipeerConnectivity delegates (called on a private queue; hop to main)

extension SyncManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self, session === self.session else { return }
            if state != .connecting, let id = self.peerDevices[peerID] {
                self.invitedDevices.remove(id)
            }
            self.refreshPeers()
            switch state {
            case .connected:
                self.engine.peerConnected(Self.key(for: peerID))
            case .notConnected:
                self.engine.peerDisconnected(Self.key(for: peerID))
                // Invitations time out or drop now and then; try again while the peer is still around.
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                    self?.inviteIfNeeded(peerID)
                }
            default:
                break
            }
        }
    }

    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self, session === self.session else { return }
            self.engine.receive(data, from: Self.key(for: peerID))
        }
    }

    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension SyncManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String: String]?) {
        DispatchQueue.main.async { [weak self] in
            guard let self, browser === self.browser else { return }
            // Same show only, and never ourselves.
            guard info?["code"] == self.showCode, let theirID = info?["id"], theirID != self.deviceID else { return }
            self.peerDevices[peerID] = theirID
            self.nearbyPeers.insert(peerID)
            self.inviteIfNeeded(peerID)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self, browser === self.browser else { return }
            self.nearbyPeers.remove(peerID)
        }
    }

    /// Only the side with the lower device ID invites, so a pair doesn't race.
    fileprivate func inviteIfNeeded(_ peerID: MCPeerID) {
        guard let session, let browser, nearbyPeers.contains(peerID),
              let theirID = peerDevices[peerID], deviceID < theirID,
              !isConnected(toDevice: theirID), !invitedDevices.contains(theirID) else { return }
        invitedDevices.insert(theirID)
        browser.invitePeer(peerID, to: session, withContext: invitationContext(), timeout: 15)
    }
}

extension SyncManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self, advertiser === self.advertiser, let session = self.session,
                  let fields = context.flatMap({ String(data: $0, encoding: .utf8) })?.split(separator: "\n", omittingEmptySubsequences: false),
                  fields.count == 2, String(fields[0]) == self.showCode else {
                invitationHandler(false, nil)
                return
            }
            let theirID = String(fields[1])
            guard theirID != self.deviceID else {
                invitationHandler(false, nil)
                return
            }
            self.peerDevices[peerID] = theirID
            invitationHandler(true, session)
        }
    }
}

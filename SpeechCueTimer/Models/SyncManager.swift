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
    /// Random per launch; decides which of two devices sends the invitation.
    @ObservationIgnored private let instanceID = UUID().uuidString

    init(engine: SyncEngine) {
        self.engine = engine
        let defaults = UserDefaults.standard
        isEnabled = defaults.bool(forKey: "syncEnabled")
        showCode = defaults.string(forKey: "syncShowCode") ?? Self.randomCode()
        deviceName = defaults.string(forKey: "syncDeviceName") ?? UIDevice.current.name
        super.init()

        defaults.set(showCode, forKey: "syncShowCode")
        engine.send = { [weak self] data, peer in self?.send(data, to: peer) }

        NotificationCenter.default.addObserver(self, selector: #selector(appDidBecomeActive), name: UIApplication.didBecomeActiveNotification, object: nil)

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

        let peerID = MCPeerID(displayName: Self.peerDisplayName(deviceName))
        let session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self

        let advertiser = MCNearbyServiceAdvertiser(
            peer: peerID,
            discoveryInfo: ["code": showCode, "id": instanceID],
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
        connectedPeerNames = []
    }

    private func restartIfEnabled() {
        if isEnabled { start() }
    }

    /// iOS tears peer connections down in the background; reconnect on return.
    @objc private func appDidBecomeActive() {
        if isEnabled && (session?.connectedPeers.isEmpty ?? true) {
            start()
        }
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

    private func refreshPeers() {
        connectedPeerNames = (session?.connectedPeers ?? []).map(\.displayName).sorted()
    }
}

// MARK: - MultipeerConnectivity delegates (called on a private queue; hop to main)

extension SyncManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self, session === self.session else { return }
            self.refreshPeers()
            switch state {
            case .connected: self.engine.peerConnected(Self.key(for: peerID))
            case .notConnected: self.engine.peerDisconnected(Self.key(for: peerID))
            default: break
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
            guard let self, browser === self.browser, let session = self.session else { return }
            // Same show only, and only one side invites so the pair doesn't race.
            guard info?["code"] == self.showCode,
                  let theirID = info?["id"], self.instanceID < theirID,
                  !session.connectedPeers.contains(peerID) else { return }
            browser.invitePeer(peerID, to: session, withContext: Data(self.showCode.utf8), timeout: 15)
        }
    }

    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}

extension SyncManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        DispatchQueue.main.async { [weak self] in
            guard let self, advertiser === self.advertiser, let session = self.session,
                  context == Data(self.showCode.utf8) else {
                invitationHandler(false, nil)
                return
            }
            invitationHandler(true, session)
        }
    }
}

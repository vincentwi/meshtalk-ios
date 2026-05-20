import Foundation
import Combine

// MARK: - Peer Model

/// Represents a connected peer on the mesh network.
struct Peer: Identifiable, Sendable {
    let id: String
    let user: String
    let joinedAt: Date
}

/// Higher-level mesh bridge protocol client.
/// Handles join/leave, audio streaming, and control messages.
@MainActor
final class MeshBridgeClient: ObservableObject {
    @Published var isConnected = false
    @Published var peerCount: Int = 0
    @Published var peers: [Peer] = []
    @Published var channel: String = "alpha"
    @Published var reconnectCount: Int = 0

    /// Flat list of peer user names for simple UI binding.
    var peerNames: [String] {
        peers.map(\.user)
    }

    private var config: MeshConfig
    private var wsClient: WebSocketClient?
    private var cancellables = Set<AnyCancellable>()
    private var onAudioReceived: ((Data) -> Void)?

    init(config: MeshConfig = MeshConfig()) {
        self.config = config
        self.channel = config.channel
    }

    func connect(onAudio: @escaping (Data) -> Void) {
        self.onAudioReceived = onAudio
        config.channel = channel

        let client = WebSocketClient(url: config.wsURL)
        self.wsClient = client

        client.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }
                let wasConnected = self.isConnected
                self.isConnected = (state == .connected)
                // Track reconnections
                if !wasConnected && self.isConnected && self.reconnectCount > 0 {
                    // This is a reconnect (not the first connect)
                }
                if wasConnected && !self.isConnected {
                    self.reconnectCount += 1
                }
            }
            .store(in: &cancellables)

        client.messagePublisher
            .sink { [weak self] message in
                self?.handleMessage(message)
            }
            .store(in: &cancellables)

        client.connect()
        print("[Bridge] Connecting to \(config.wsURL)")
    }

    func disconnect() {
        wsClient?.disconnect()
        wsClient = nil
        cancellables.removeAll()
        isConnected = false
        peers = []
        peerCount = 0
    }

    func switchChannel(_ newChannel: String) {
        channel = newChannel
        sendControl(["cmd": "switch", "channel": newChannel])
    }

    func sendAudio(_ data: Data) {
        wsClient?.send(data: data)
    }

    func sendControl(_ message: [String: Any]) {
        if let jsonData = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            wsClient?.send(text: jsonString)
        }
    }

    func updateHost(_ host: String) {
        config.host = host
    }

    private nonisolated func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .data(let data):
            // Binary message = audio data
            Task { @MainActor [weak self] in
                self?.onAudioReceived?(data)
            }
        case .string(let text):
            // JSON control message
            guard let data = text.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                return
            }
            Task { @MainActor [weak self] in
                self?.handleControlMessage(json)
            }
        @unknown default:
            break
        }
    }

    private func handleControlMessage(_ json: [String: Any]) {
        if let type = json["event"] as? String {
            switch type {
            case "peers":
                if let peerList = json["peers"] as? [[String: Any]] {
                    peers = peerList.compactMap { dict -> Peer? in
                        guard let user = dict["user"] as? String else { return nil }
                        let id = (dict["id"] as? String) ?? user
                        let joinedAt: Date
                        if let ts = dict["joined_at"] as? TimeInterval {
                            joinedAt = Date(timeIntervalSince1970: ts)
                        } else if let tsStr = dict["joined_at"] as? String,
                                  let tsDouble = Double(tsStr) {
                            joinedAt = Date(timeIntervalSince1970: tsDouble)
                        } else {
                            joinedAt = Date()
                        }
                        return Peer(id: id, user: user, joinedAt: joinedAt)
                    }
                    peerCount = peers.count
                }
            case "peer_count":
                if let count = json["count"] as? Int {
                    peerCount = count
                }
            case "join":
                if let user = json["user"] as? String {
                    let id = (json["id"] as? String) ?? user
                    // Don't add duplicates
                    if !peers.contains(where: { $0.id == id }) {
                        let peer = Peer(id: id, user: user, joinedAt: Date())
                        peers.append(peer)
                    }
                    // Bridge sends "peer_count" as integer alongside join events
                    if let pc = json["peer_count"] as? Int {
                        peerCount = pc
                    } else {
                        peerCount = peers.count
                    }
                    print("[Bridge] Peer joined: \(user)")
                }
            case "leave":
                if let user = json["user"] as? String {
                    let id = (json["id"] as? String) ?? user
                    peers.removeAll { $0.id == id || $0.user == user }
                    // Bridge sends "peer_count" as integer alongside leave events
                    if let pc = json["peer_count"] as? Int {
                        peerCount = pc
                    } else {
                        peerCount = peers.count
                    }
                    print("[Bridge] Peer left: \(user)")
                }
            case "switched":
                if let newCh = json["channel"] as? String {
                    channel = newCh
                    print("[Bridge] Channel switched to: \(newCh)")
                }
            case "pong":
                // Keepalive response — no action needed
                break
            default:
                print("[Bridge] Unknown control: \(type)")
            }
        }
    }
}

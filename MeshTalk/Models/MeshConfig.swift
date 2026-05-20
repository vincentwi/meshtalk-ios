import Foundation

struct MeshConfig: Sendable {
    var host: String = "10.0.200.221"
    var port: Int = 8440
    var channel: String = "alpha"
    var userName: String = "iPhone"
    var audioFormat: String = "pcm16"
    var sampleRate: Double = 16000
    var frameSize: Int = 3200  // 100ms at 16kHz mono PCM16
    var voxThreshold: Float = 0.015
    var voxHangTime: TimeInterval = 0.8

    // MARK: - UserDefaults Keys
    private static let hostKey = "meshtalk_host"
    private static let portKey = "meshtalk_port"
    private static let channelKey = "meshtalk_channel"
    private static let userNameKey = "meshtalk_username"
    private static let clientIDKey = "meshtalk_client_id"

    var clientID: String {
        let defaults = UserDefaults.standard
        if let saved = defaults.string(forKey: MeshConfig.clientIDKey) {
            return saved
        }
        let id = "iphone_\(UUID().uuidString.prefix(8).lowercased())"
        defaults.set(id, forKey: MeshConfig.clientIDKey)
        return id
    }

    var wsURL: URL {
        var components = URLComponents()
        components.scheme = "ws"
        components.host = host
        components.port = port
        components.path = "/ws/talk"
        components.queryItems = [
            URLQueryItem(name: "id", value: clientID),
            URLQueryItem(name: "channel", value: channel),
            URLQueryItem(name: "user", value: userName),
            URLQueryItem(name: "format", value: audioFormat)
        ]
        return components.url!
    }

    static let availableChannels = ["alpha", "bravo"]

    // MARK: - Persistence

    /// Save current config values to UserDefaults for @AppStorage compatibility.
    mutating func save() {
        let defaults = UserDefaults.standard
        defaults.set(host, forKey: MeshConfig.hostKey)
        defaults.set(port, forKey: MeshConfig.portKey)
        defaults.set(channel, forKey: MeshConfig.channelKey)
        defaults.set(userName, forKey: MeshConfig.userNameKey)
    }

    /// Load config from UserDefaults, falling back to defaults.
    static func load() -> MeshConfig {
        let defaults = UserDefaults.standard
        var config = MeshConfig()
        if let savedHost = defaults.string(forKey: hostKey), !savedHost.isEmpty {
            config.host = savedHost
        }
        let savedPort = defaults.integer(forKey: portKey)
        if savedPort > 0 {
            config.port = savedPort
        }
        if let savedChannel = defaults.string(forKey: channelKey), !savedChannel.isEmpty {
            config.channel = savedChannel
        }
        if let savedUserName = defaults.string(forKey: userNameKey), !savedUserName.isEmpty {
            config.userName = savedUserName
        }
        return config
    }
}

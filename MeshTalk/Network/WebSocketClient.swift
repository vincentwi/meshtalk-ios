import Foundation
import Combine

/// Low-level WebSocket client using URLSessionWebSocketTask with auto-reconnect.
final class WebSocketClient: NSObject, Sendable, URLSessionWebSocketDelegate {

    enum ConnectionState: Sendable {
        case disconnected
        case connecting
        case connected
    }

    private let url: URL
    private let stateSubject = PassthroughSubject<ConnectionState, Never>()
    private let messageSubject = PassthroughSubject<URLSessionWebSocketTask.Message, Never>()

    private let sessionQueue = DispatchQueue(label: "com.openclaw.meshtalk.ws")
    private let lock = NSLock()

    private var session: URLSession?
    private var task: URLSessionWebSocketTask?
    private var _state: ConnectionState = .disconnected
    private var reconnectAttempt = 0
    private var maxReconnectDelay: TimeInterval = 30
    private var shouldReconnect = false

    var statePublisher: AnyPublisher<ConnectionState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var messagePublisher: AnyPublisher<URLSessionWebSocketTask.Message, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    var state: ConnectionState {
        lock.lock()
        defer { lock.unlock() }
        return _state
    }

    init(url: URL) {
        self.url = url
        super.init()
    }

    func connect() {
        lock.lock()
        shouldReconnect = true
        guard _state == .disconnected else {
            lock.unlock()
            return
        }
        _state = .connecting
        lock.unlock()

        stateSubject.send(.connecting)

        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = true
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        let task = session.webSocketTask(with: url)

        lock.lock()
        self.session = session
        self.task = task
        lock.unlock()

        task.resume()
        receiveMessage()
    }

    func disconnect() {
        lock.lock()
        shouldReconnect = false
        let currentTask = task
        task = nil
        _state = .disconnected
        lock.unlock()

        currentTask?.cancel(with: .goingAway, reason: nil)
        stateSubject.send(.disconnected)
    }

    func send(data: Data) {
        lock.lock()
        let currentTask = task
        lock.unlock()

        currentTask?.send(.data(data)) { error in
            if let error = error {
                print("[WS] Send binary error: \(error)")
            }
        }
    }

    func send(text: String) {
        lock.lock()
        let currentTask = task
        lock.unlock()

        currentTask?.send(.string(text)) { error in
            if let error = error {
                print("[WS] Send text error: \(error)")
            }
        }
    }

    private func receiveMessage() {
        lock.lock()
        let currentTask = task
        lock.unlock()

        currentTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let message):
                self.messageSubject.send(message)
                self.receiveMessage()
            case .failure(let error):
                print("[WS] Receive error: \(error)")
                self.handleDisconnect()
            }
        }
    }

    private func handleDisconnect() {
        lock.lock()
        _state = .disconnected
        let shouldReconnect = self.shouldReconnect
        lock.unlock()

        stateSubject.send(.disconnected)

        if shouldReconnect {
            scheduleReconnect()
        }
    }

    private func scheduleReconnect() {
        lock.lock()
        reconnectAttempt += 1
        let attempt = reconnectAttempt
        lock.unlock()

        let delay = min(pow(2.0, Double(attempt - 1)), maxReconnectDelay)
        print("[WS] Reconnecting in \(delay)s (attempt \(attempt))")

        DispatchQueue.global().asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }
            self.lock.lock()
            let shouldReconnect = self.shouldReconnect
            self._state = .disconnected
            self.task = nil
            self.lock.unlock()

            if shouldReconnect {
                self.connect()
            }
        }
    }

    // MARK: - URLSessionWebSocketDelegate

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        lock.lock()
        _state = .connected
        reconnectAttempt = 0
        lock.unlock()

        stateSubject.send(.connected)
        print("[WS] Connected to \(url)")
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        print("[WS] Closed with code: \(closeCode)")
        handleDisconnect()
    }
}

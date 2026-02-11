import Foundation
import OSLog

@Observable
final class WebSocketManager {
    enum ConnectionState: Equatable {
        case disconnected
        case connecting
        case connected
        case authenticated
        case reconnecting(attempt: Int)
    }

    private(set) var connectionState: ConnectionState = .disconnected
    private var webSocketTask: URLSessionWebSocketTask?
    private var reconnectAttempts = 0
    private let maxReconnectDelay = 30.0
    private let logger = Logger.category(.networking)
    private var pingTimer: Timer?

    var onMessage: ((WebSocketMessage) -> Void)?

    func connect(to url: URL) {
        guard connectionState == .disconnected else {
            logger.warning("Already connecting/connected, ignoring connect request")
            return
        }

        connectionState = .connecting
        logger.info("Connecting to WebSocket: \(url.absoluteString)")

        webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask?.resume()

        connectionState = .connected
        reconnectAttempts = 0

        // Start receiving messages
        receiveMessage()

        // Start ping timer (15s interval)
        schedulePing()

        // Subscribe to all channels
        send(message: .subscribe(channels: ["jordan", "hunter", "bob", "clawd", "events"]))
        logger.info("WebSocket connected and subscribed to channels")
    }

    private func receiveMessage() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let message):
                switch message {
                case .string(let text):
                    if let data = text.data(using: .utf8),
                       let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                        self.handleMessage(wsMessage)
                    }
                case .data(let data):
                    if let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                        self.handleMessage(wsMessage)
                    }
                @unknown default:
                    break
                }

                // Continue listening
                self.receiveMessage()

            case .failure(let error):
                self.logger.error("WebSocket receive error: \(error.localizedDescription)")
                self.handleDisconnection()
            }
        }
    }

    private func handleMessage(_ message: WebSocketMessage) {
        logger.debug("WebSocket received: \(message.type)")

        switch message.type {
        case "PONG":
            // Keep-alive acknowledged
            logger.debug("Received PONG")
        case "SUBSCRIBED":
            connectionState = .authenticated
            logger.info("WebSocket authenticated")
        case "TRADE_EXECUTED", "LEAD_QUALIFIED", "AGENT_STATE_CHANGE", "STATUS_REPORT":
            // Forward to handler
            onMessage?(message)
        default:
            logger.debug("Unhandled message type: \(message.type)")
        }
    }

    private func handleDisconnection() {
        pingTimer?.invalidate()
        pingTimer = nil

        connectionState = .reconnecting(attempt: reconnectAttempts)

        let delay = min(pow(2.0, Double(reconnectAttempts)), maxReconnectDelay)
        reconnectAttempts += 1

        logger.info("Reconnecting in \(String(format: "%.0f", delay))s (attempt \(reconnectAttempts))")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            // Retry connection
            if let url = self.webSocketTask?.currentRequest?.url {
                self.webSocketTask = nil
                self.connectionState = .disconnected
                self.connect(to: url)
            }
        }
    }

    private func schedulePing() {
        pingTimer?.invalidate()

        pingTimer = Timer.scheduledTimer(withTimeInterval: 15.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }

            if case .connected = self.connectionState {
                self.send(message: .ping)
                self.logger.debug("Sent PING")
            } else if case .authenticated = self.connectionState {
                self.send(message: .ping)
                self.logger.debug("Sent PING")
            }
        }
    }

    func send(message: WebSocketMessage) {
        guard let data = try? JSONEncoder().encode(message),
              let text = String(data: data, encoding: .utf8) else {
            logger.error("Failed to encode WebSocket message")
            return
        }

        webSocketTask?.send(.string(text)) { [weak self] error in
            if let error = error {
                self?.logger.error("WebSocket send error: \(error.localizedDescription)")
            }
        }
    }

    func disconnect() {
        logger.info("Disconnecting WebSocket")
        pingTimer?.invalidate()
        pingTimer = nil
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionState = .disconnected
        reconnectAttempts = 0
    }
}

// MARK: - WebSocketMessage

struct WebSocketMessage: Codable, Sendable {
    let type: String
    let source: String?
    let timestamp: String?
    let payload: [String: AnyCodable]?

    init(type: String, source: String?, timestamp: String?, payload: [String: AnyCodable]?) {
        self.type = type
        self.source = source
        self.timestamp = timestamp
        self.payload = payload
    }

    static let ping = WebSocketMessage(type: "PING", source: nil, timestamp: nil, payload: nil)

    static func subscribe(channels: [String]) -> WebSocketMessage {
        WebSocketMessage(
            type: "SUBSCRIBE",
            source: "ios_app",
            timestamp: ISO8601DateFormatter().string(from: Date()),
            payload: ["channels": AnyCodable(channels)]
        )
    }
}

import Foundation

enum AppError: LocalizedError {
    // Network errors
    case networkUnavailable
    case requestTimeout
    case invalidResponse(statusCode: Int)
    case decodingFailed(underlyingError: Error)
    case serverError(message: String)

    // Gateway errors
    case gatewayNotConnected
    case gatewayDiscoveryFailed
    case gatewayAuthFailed

    // Data errors
    case persistenceFailure(operation: String, underlyingError: Error)
    case invalidData(reason: String)

    // Voice errors
    case microphonePermissionDenied
    case speechRecognitionFailed(reason: String)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "No internet connection. Please check your network settings."
        case .requestTimeout:
            return "Request timed out. Please try again."
        case .invalidResponse(let statusCode):
            return "Server returned error (code \(statusCode))"
        case .decodingFailed:
            return "Failed to parse server response"
        case .serverError(let message):
            return message
        case .gatewayNotConnected:
            return "Gateway is not connected. Check Settings."
        case .gatewayDiscoveryFailed:
            return "Could not find gateway on local network"
        case .gatewayAuthFailed:
            return "Gateway authentication failed. Check your credentials."
        case .persistenceFailure(let operation, _):
            return "Failed to \(operation) data"
        case .invalidData(let reason):
            return "Invalid data: \(reason)"
        case .microphonePermissionDenied:
            return "Microphone access is required for voice commands. Enable in Settings."
        case .speechRecognitionFailed(let reason):
            return "Speech recognition failed: \(reason)"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkUnavailable:
            return "Check your WiFi or cellular connection"
        case .requestTimeout:
            return "Try again in a moment"
        case .gatewayNotConnected:
            return "Tap Settings to connect to your gateway"
        case .gatewayDiscoveryFailed:
            return "Ensure your gateway is running and on the same network"
        case .microphonePermissionDenied:
            return "Go to Settings > Privacy > Microphone and enable for Clawdbot"
        default:
            return nil
        }
    }

    var shouldRetry: Bool {
        switch self {
        case .networkUnavailable, .requestTimeout, .invalidResponse:
            return true
        default:
            return false
        }
    }
}

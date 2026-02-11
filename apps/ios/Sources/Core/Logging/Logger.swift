import OSLog

enum LogCategory: String {
    case networking = "com.clawdbot.network"
    case gateway = "com.clawdbot.gateway"
    case voice = "com.clawdbot.voice"
    case persistence = "com.clawdbot.persistence"
    case ui = "com.clawdbot.ui"
}

extension Logger {
    static func category(_ category: LogCategory) -> Logger {
        Logger(subsystem: "com.clawdbot.ios", category: category.rawValue)
    }

    // Convenience methods with privacy controls
    func logNetworkRequest(url: String, method: String) {
        info("[\(method)] \(url, privacy: .public)")
    }

    func logNetworkResponse(url: String, statusCode: Int, duration: TimeInterval) {
        info("[\(statusCode)] \(url, privacy: .public) (\(String(format: "%.2f", duration))ms)")
    }

    func logNetworkError(url: String, error: Error) {
        self.error("Network error for \(url, privacy: .public): \(error.localizedDescription)")
    }
}

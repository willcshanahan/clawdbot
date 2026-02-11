import Foundation
import OSLog

/// ClawdV2Client provides API access to Clawd V2 backend services
/// Connects to localhost:8420 for trading, status, briefing, pipeline, and approvals
@Observable
final class ClawdV2Client: Sendable {
    private let baseURL: URL
    private let logger = Logger.category(.networking)

    init() {
        // Read from UserDefaults (synced with @AppStorage in Settings)
        let host = UserDefaults.standard.string(forKey: "backend.api.host") ?? "34.162.104.8"
        let port = UserDefaults.standard.integer(forKey: "backend.api.port")
        let actualPort = port > 0 ? port : 8420
        self.baseURL = URL(string: "http://\(host):\(actualPort)")!
    }

    init(host: String, port: Int) {
        self.baseURL = URL(string: "http://\(host):\(port)")!
    }

    // MARK: - Trading

    func fetchTrades(limit: Int = 20) async throws -> TradesResponse {
        let url = baseURL.appendingPathComponent("trades").appending(queryItems: [
            URLQueryItem(name: "limit", value: "\(limit)"),
        ])
        return try await get(url)
    }

    func fetchPositions() async throws -> PositionsResponse {
        let url = baseURL.appendingPathComponent("trades/positions")
        return try await get(url)
    }

    func fetchPnLHistory(days: Int = 30) async throws -> PnLHistoryResponse {
        let url = baseURL.appendingPathComponent("trades/pnl-history").appending(queryItems: [
            URLQueryItem(name: "days", value: "\(days)"),
        ])
        return try await get(url)
    }

    func fetchTradeStats() async throws -> TradeStatsResponse {
        let url = baseURL.appendingPathComponent("trades/stats")
        return try await get(url)
    }

    func fetchForensics() async throws -> ForensicsResponse {
        let url = baseURL.appendingPathComponent("forensics")
        return try await get(url)
    }

    // MARK: - Pipeline (Hunter)

    func fetchDrafts() async throws -> DraftsResponse {
        let url = baseURL.appendingPathComponent("pipeline/drafts")
        return try await get(url)
    }

    func approveDraft(_ id: Int) async throws {
        let url = baseURL.appendingPathComponent("pipeline/drafts/\(id)/approve")
        logger.logNetworkRequest(url: url.absoluteString, method: "POST")
        let start = Date()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (_, response) = try await NetworkConfiguration.urlSession.data(for: request)
            let duration = Date().timeIntervalSince(start) * 1000
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
        } catch {
            logger.logNetworkError(url: url.absoluteString, error: error)
            throw error
        }
    }

    func dismissDraft(_ id: Int) async throws {
        let url = baseURL.appendingPathComponent("pipeline/drafts/\(id)/dismiss")
        logger.logNetworkRequest(url: url.absoluteString, method: "POST")
        let start = Date()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (_, response) = try await NetworkConfiguration.urlSession.data(for: request)
            let duration = Date().timeIntervalSince(start) * 1000
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
            logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
        } catch {
            logger.logNetworkError(url: url.absoluteString, error: error)
            throw error
        }
    }

    // MARK: - Chat

    func sendChat(message: String) async throws -> ChatResponse {
        let url = baseURL.appendingPathComponent("chat").appending(queryItems: [
            URLQueryItem(name: "message", value: message),
        ])
        logger.logNetworkRequest(url: url.absoluteString, method: "POST")
        let start = Date()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        do {
            let (data, response) = try await NetworkConfiguration.urlSession.data(for: request)
            let duration = Date().timeIntervalSince(start) * 1000
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
                throw ClawdV2Error.requestFailed
            }

            logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
            return try JSONDecoder().decode(ChatResponse.self, from: data)
        } catch {
            logger.logNetworkError(url: url.absoluteString, error: error)
            throw error
        }
    }

    // MARK: - Status

    func fetchStatus() async throws -> AgentStatusResponse {
        let url = baseURL.appendingPathComponent("status")
        return try await get(url)
    }

    // MARK: - Briefing

    func fetchBriefing() async throws -> BriefingResponse {
        let url = baseURL.appendingPathComponent("briefing")
        return try await get(url)
    }

    // MARK: - Pipeline

    func fetchPipeline() async throws -> PipelineResponse {
        let url = baseURL.appendingPathComponent("pipeline")
        return try await get(url)
    }

    // MARK: - Approvals

    func fetchApprovals() async throws -> ApprovalsResponse {
        let url = baseURL.appendingPathComponent("approvals")
        return try await get(url)
    }

    // MARK: - Auth

    func login(token: String) async throws -> AuthResponse {
        let url = baseURL.appendingPathComponent("auth/login")
        logger.logNetworkRequest(url: url.absoluteString, method: "POST")
        let start = Date()

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["token": token])

        do {
            let (data, response) = try await NetworkConfiguration.urlSession.data(for: request)
            let duration = Date().timeIntervalSince(start) * 1000
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
                throw ClawdV2Error.requestFailed
            }

            logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
            return try JSONDecoder().decode(AuthResponse.self, from: data)
        } catch {
            logger.logNetworkError(url: url.absoluteString, error: error)
            throw error
        }
    }

    // MARK: - Aggregated Dashboard

    func fetchAggregatedDashboard() async throws -> AggregatedDashboardResponse {
        let url = baseURL.appendingPathComponent("dashboard/aggregated")
        return try await get(url)
    }

    // MARK: - Private

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        logger.logNetworkRequest(url: url.absoluteString, method: "GET")
        let start = Date()

        do {
            let (data, response) = try await NetworkConfiguration.urlSession.data(from: url)
            let duration = Date().timeIntervalSince(start) * 1000
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0

            guard let http = response as? HTTPURLResponse, (200 ... 299).contains(http.statusCode) else {
                logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)
                throw ClawdV2Error.requestFailed
            }

            logger.logNetworkResponse(url: url.absoluteString, statusCode: statusCode, duration: duration)

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(T.self, from: data)
        } catch {
            logger.logNetworkError(url: url.absoluteString, error: error)
            throw error
        }
    }
}

enum ClawdV2Error: Error, LocalizedError {
    case requestFailed

    var errorDescription: String? {
        switch self {
        case .requestFailed: "Failed to connect to Clawd V2 API"
        }
    }
}

// MARK: - Response Types

struct AgentStatusResponse: Codable, Sendable {
    let agents: [String: AgentState]?
}

struct AgentState: Codable, Sendable, Identifiable {
    var id: String { name }
    let name: String
    let status: String?
    let lastHeartbeat: String?
    let emotionalState: String?

    enum CodingKeys: String, CodingKey {
        case name, status
        case lastHeartbeat = "last_heartbeat"
        case emotionalState = "emotional_state"
    }
}

struct BriefingResponse: Codable, Sendable {
    let type: String?
    let summary: String?
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case type, summary
        case generatedAt = "generated_at"
    }
}

struct PipelineResponse: Codable, Sendable {
    let totalLeads: Int?
    let activeLeads: Int?
    let conversionRate: Double?

    enum CodingKeys: String, CodingKey {
        case totalLeads = "total_leads"
        case activeLeads = "active_leads"
        case conversionRate = "conversion_rate"
    }
}

struct ApprovalsResponse: Codable, Sendable {
    let pending: [PendingApproval]?
}

struct PendingApproval: Codable, Identifiable, Sendable {
    let id: String
    let description: String
    let agentName: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, description
        case agentName = "agent_name"
        case createdAt = "created_at"
    }
}

// TradesResponse, PositionsResponse, PnLHistoryResponse, TradeStatsResponse,
// ForensicsResponse defined in Models/Trade.swift

struct DraftsResponse: Codable, Sendable {
    let drafts: [HunterDraft]
}

struct HunterDraft: Codable, Identifiable, Sendable {
    let id: Int
    let prospectName: String?
    let companyName: String?
    let personaType: String?
    let personalizationHook: String?
    let subject: String?
    let body: String?
    let genericScore: Double?
    let personalizationScore: Double?
    let status: String?
    let followUpNumber: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, subject, body, status
        case prospectName = "prospect_name"
        case companyName = "company_name"
        case personaType = "persona_type"
        case personalizationHook = "personalization_hook"
        case genericScore = "generic_score"
        case personalizationScore = "personalization_score"
        case followUpNumber = "follow_up_number"
        case createdAt = "created_at"
    }
}

struct ChatResponse: Codable, Sendable {
    let reply: String?
    let status: String?
    let error: String?
}

struct AuthResponse: Codable, Sendable {
    let sessionToken: String
    let expiresIn: Int
    let userId: String

    enum CodingKeys: String, CodingKey {
        case sessionToken = "session_token"
        case expiresIn = "expires_in"
        case userId = "user_id"
    }
}

struct AggregatedDashboardResponse: Codable, Sendable {
    let agents: [String: AgentState]?
    let briefing: BriefingResponse?
    let pipeline: PipelineResponse?
    let approvals: ApprovalsResponse?
    let timestamp: String?
}

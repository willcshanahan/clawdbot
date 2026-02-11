import SwiftData
import OSLog
import Foundation

protocol TradeRepositoryProtocol {
    func fetchAll() async throws -> [TradeRecord]
    func fetchOpen() async throws -> [TradeRecord]
    func fetchClosed(limit: Int) async throws -> [TradeRecord]
}

final class TradeRepository: TradeRepositoryProtocol {
    private let modelContext: ModelContext
    private let syncManager: SyncManager
    private let logger = Logger.category(.persistence)

    init(modelContext: ModelContext, syncManager: SyncManager) {
        self.modelContext = modelContext
        self.syncManager = syncManager
    }

    /// Fetch all trades (offline-first: try sync, fallback to cache)
    func fetchAll() async throws -> [TradeRecord] {
        try? await syncManager.syncTrades()

        let descriptor = FetchDescriptor<TradeEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toTradeRecord() }
    }

    /// Fetch open trades
    func fetchOpen() async throws -> [TradeRecord] {
        try? await syncManager.syncTrades()

        let descriptor = FetchDescriptor<TradeEntity>(
            predicate: #Predicate { $0.status == "OPEN" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toTradeRecord() }
    }

    /// Fetch closed trades with limit
    func fetchClosed(limit: Int = 50) async throws -> [TradeRecord] {
        try? await syncManager.syncTrades()

        var descriptor = FetchDescriptor<TradeEntity>(
            predicate: #Predicate { $0.status == "CLOSED" || $0.status == "SETTLED" },
            sortBy: [SortDescriptor(\.closedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let entities = try modelContext.fetch(descriptor)
        return entities.map { $0.toTradeRecord() }
    }
}

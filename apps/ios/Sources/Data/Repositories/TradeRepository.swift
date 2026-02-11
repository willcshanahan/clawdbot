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
        // Try to sync from API (fire and forget - don't block on errors)
        Task {
            do {
                try await syncManager.syncTrades()
            } catch {
                logger.warning("Background sync failed, using cached data: \(error.localizedDescription)")
            }
        }

        // Return from local cache immediately
        let descriptor = FetchDescriptor<TradeEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        logger.info("Fetched \(entities.count) trades from local cache")
        return entities.map { $0.toTradeRecord() }
    }

    /// Fetch open trades
    func fetchOpen() async throws -> [TradeRecord] {
        // Try to sync from API (fire and forget)
        Task {
            do {
                try await syncManager.syncTrades()
            } catch {
                logger.warning("Background sync failed, using cached data: \(error.localizedDescription)")
            }
        }

        let descriptor = FetchDescriptor<TradeEntity>(
            predicate: #Predicate { $0.status == "OPEN" },
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        let entities = try modelContext.fetch(descriptor)
        logger.info("Fetched \(entities.count) open trades from local cache")
        return entities.map { $0.toTradeRecord() }
    }

    /// Fetch closed trades with limit
    func fetchClosed(limit: Int = 50) async throws -> [TradeRecord] {
        // Try to sync from API (fire and forget)
        Task {
            do {
                try await syncManager.syncTrades()
            } catch {
                logger.warning("Background sync failed, using cached data: \(error.localizedDescription)")
            }
        }

        var descriptor = FetchDescriptor<TradeEntity>(
            predicate: #Predicate { $0.status == "CLOSED" || $0.status == "SETTLED" },
            sortBy: [SortDescriptor(\.closedAt, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let entities = try modelContext.fetch(descriptor)
        logger.info("Fetched \(entities.count) closed trades from local cache")
        return entities.map { $0.toTradeRecord() }
    }
}

import SwiftData
import OSLog
import Foundation

@Observable
final class SyncManager {
    enum SyncState {
        case idle
        case syncing
        case failed(AppError)
    }

    private(set) var state: SyncState = .idle
    private let modelContext: ModelContext
    private let apiClient: ClawdV2Client
    private let logger = Logger.category(.persistence)

    init(modelContext: ModelContext, apiClient: ClawdV2Client) {
        self.modelContext = modelContext
        self.apiClient = apiClient
    }

    /// Sync trades from API to local database
    func syncTrades() async throws {
        state = .syncing
        logger.info("Starting trades sync")

        do {
            // Fetch from API
            let response = try await apiClient.fetchTrades(limit: 100)
            logger.info("Fetched \(response.trades.count) trades from API")

            // Upsert to local database
            for tradeRecord in response.trades {
                let tradeId = "\(tradeRecord.id)"
                let descriptor = FetchDescriptor<TradeEntity>(
                    predicate: #Predicate { $0.id == tradeId }
                )

                if let existing = try modelContext.fetch(descriptor).first {
                    // Update existing trade
                    existing.exitPriceCents = tradeRecord.exitPriceCents
                    existing.pnlCents = tradeRecord.pnlCents ?? 0
                    existing.status = tradeRecord.status
                    existing.closedAt = tradeRecord.closedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
                    existing.settledAt = tradeRecord.settledAt.flatMap { ISO8601DateFormatter().date(from: $0) }
                    existing.lastSyncedAt = Date()
                    existing.needsSync = false
                    logger.debug("Updated existing trade: \(tradeId)")
                } else {
                    // Insert new trade
                    let entity = TradeEntity(from: tradeRecord)
                    modelContext.insert(entity)
                    logger.debug("Inserted new trade: \(tradeId)")
                }
            }

            try modelContext.save()
            state = .idle
            logger.info("Trades sync completed: \(response.trades.count) trades")
        } catch let error as AppError {
            state = .failed(error)
            logger.error("Trades sync failed: \(error.localizedDescription)")
            throw error
        } catch {
            let appError = AppError.persistenceFailure(operation: "sync trades", underlyingError: error)
            state = .failed(appError)
            logger.error("Trades sync failed: \(error.localizedDescription)")
            throw appError
        }
    }

    /// Sync positions from API to local database
    func syncPositions() async throws {
        state = .syncing
        logger.info("Starting positions sync")

        do {
            // Fetch from API
            let response = try await apiClient.fetchPositions()
            logger.info("Fetched \(response.positions.count) positions from API")

            // First, mark all existing positions for cleanup
            let allDescriptor = FetchDescriptor<PositionEntity>()
            let allPositions = try modelContext.fetch(allDescriptor)
            for position in allPositions {
                position.needsSync = true
            }

            // Upsert positions from API
            for positionRecord in response.positions {
                let positionId = "\(positionRecord.id)"
                let descriptor = FetchDescriptor<PositionEntity>(
                    predicate: #Predicate { $0.id == positionId }
                )

                if let existing = try modelContext.fetch(descriptor).first {
                    // Update existing position
                    existing.quantity = positionRecord.quantity
                    existing.currentPriceCents = positionRecord.currentPriceCents
                    existing.unrealizedPnlCents = positionRecord.unrealizedPnlCents ?? 0
                    existing.updatedAt = positionRecord.updatedAt.flatMap { ISO8601DateFormatter().date(from: $0) }
                    existing.lastSyncedAt = Date()
                    existing.needsSync = false
                    logger.debug("Updated existing position: \(positionId)")
                } else {
                    // Insert new position
                    let entity = PositionEntity(from: positionRecord)
                    modelContext.insert(entity)
                    logger.debug("Inserted new position: \(positionId)")
                }
            }

            // Delete positions that are no longer in API response (closed positions)
            let stalePositions = allPositions.filter { $0.needsSync }
            for stalePosition in stalePositions {
                modelContext.delete(stalePosition)
                logger.debug("Deleted stale position: \(stalePosition.id)")
            }

            try modelContext.save()
            state = .idle
            logger.info("Positions sync completed: \(response.positions.count) positions, \(stalePositions.count) deleted")
        } catch let error as AppError {
            state = .failed(error)
            logger.error("Positions sync failed: \(error.localizedDescription)")
            throw error
        } catch {
            let appError = AppError.persistenceFailure(operation: "sync positions", underlyingError: error)
            state = .failed(appError)
            logger.error("Positions sync failed: \(error.localizedDescription)")
            throw appError
        }
    }

    /// Sync all data from API
    func syncAll() async throws {
        async let tradesResult = syncTrades()
        async let positionsResult = syncPositions()

        try await tradesResult
        try await positionsResult
    }
}

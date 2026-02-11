import SwiftData
import Foundation

@Model
final class PositionEntity {
    @Attribute(.unique) var id: String
    var marketId: Int
    var marketTitle: String
    var side: String  // "YES" or "NO"
    var quantity: Int
    var avgPriceCents: Int
    var currentPriceCents: Int?
    var unrealizedPnlCents: Int
    var createdAt: Date?
    var updatedAt: Date?

    // Sync metadata
    var lastSyncedAt: Date?
    var needsSync: Bool

    init(
        id: String,
        marketId: Int,
        marketTitle: String,
        side: String,
        quantity: Int,
        avgPriceCents: Int,
        currentPriceCents: Int?,
        unrealizedPnlCents: Int,
        createdAt: Date?,
        updatedAt: Date?,
        lastSyncedAt: Date? = Date(),
        needsSync: Bool = false
    ) {
        self.id = id
        self.marketId = marketId
        self.marketTitle = marketTitle
        self.side = side
        self.quantity = quantity
        self.avgPriceCents = avgPriceCents
        self.currentPriceCents = currentPriceCents
        self.unrealizedPnlCents = unrealizedPnlCents
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
    }

    /// Convert from API Position to SwiftData entity
    convenience init(from position: Position) {
        let dateFormatter = ISO8601DateFormatter()

        self.init(
            id: "\(position.id)",
            marketId: position.marketId,
            marketTitle: position.marketTitle,
            side: position.side,
            quantity: position.quantity,
            avgPriceCents: position.avgPriceCents,
            currentPriceCents: position.currentPriceCents,
            unrealizedPnlCents: position.unrealizedPnlCents ?? 0,
            createdAt: position.createdAt.flatMap { dateFormatter.date(from: $0) },
            updatedAt: position.updatedAt.flatMap { dateFormatter.date(from: $0) },
            lastSyncedAt: Date(),
            needsSync: false
        )
    }

    /// Convert entity back to API model for display
    func toPosition() -> Position {
        let dateFormatter = ISO8601DateFormatter()

        return Position(
            id: Int(id) ?? 0,
            marketId: marketId,
            marketTitle: marketTitle,
            side: side,
            quantity: quantity,
            avgPrice: Double(avgPriceCents) / 100.0,
            currentPrice: currentPriceCents.map { Double($0) / 100.0 },
            unrealizedPnlCents: unrealizedPnlCents,
            createdAt: createdAt.map { dateFormatter.string(from: $0) },
            updatedAt: updatedAt.map { dateFormatter.string(from: $0) }
        )
    }
}

import SwiftData
import Foundation

@Model
final class TradeEntity {
    @Attribute(.unique) var id: String
    var marketId: Int
    var marketTitle: String
    var side: String  // "YES" or "NO"
    var quantity: Int
    var entryPriceCents: Int
    var exitPriceCents: Int?
    var pnlCents: Int
    var status: String  // "OPEN", "CLOSED", "SETTLED"
    var thesis: String?
    var probabilityEstimate: Double?
    var edgePct: Double?
    var emotionalState: String?
    var createdAt: Date
    var closedAt: Date?
    var settledAt: Date?

    // Sync metadata
    var lastSyncedAt: Date?
    var needsSync: Bool

    init(
        id: String,
        marketId: Int,
        marketTitle: String,
        side: String,
        quantity: Int,
        entryPriceCents: Int,
        exitPriceCents: Int?,
        pnlCents: Int,
        status: String,
        thesis: String?,
        probabilityEstimate: Double?,
        edgePct: Double?,
        emotionalState: String?,
        createdAt: Date,
        closedAt: Date?,
        settledAt: Date?,
        lastSyncedAt: Date? = Date(),
        needsSync: Bool = false
    ) {
        self.id = id
        self.marketId = marketId
        self.marketTitle = marketTitle
        self.side = side
        self.quantity = quantity
        self.entryPriceCents = entryPriceCents
        self.exitPriceCents = exitPriceCents
        self.pnlCents = pnlCents
        self.status = status
        self.thesis = thesis
        self.probabilityEstimate = probabilityEstimate
        self.edgePct = edgePct
        self.emotionalState = emotionalState
        self.createdAt = createdAt
        self.closedAt = closedAt
        self.settledAt = settledAt
        self.lastSyncedAt = lastSyncedAt
        self.needsSync = needsSync
    }

    /// Convert from API TradeRecord to SwiftData entity
    convenience init(from record: TradeRecord) {
        let dateFormatter = ISO8601DateFormatter()

        self.init(
            id: "\(record.id)",
            marketId: record.marketId,
            marketTitle: record.marketTitle,
            side: record.side,
            quantity: record.quantity,
            entryPriceCents: record.entryPriceCents,
            exitPriceCents: record.exitPriceCents,
            pnlCents: record.pnlCents ?? 0,
            status: record.status,
            thesis: record.thesis,
            probabilityEstimate: record.probabilityEstimate,
            edgePct: record.edgePct,
            emotionalState: record.emotionalState,
            createdAt: dateFormatter.date(from: record.createdAt) ?? Date(),
            closedAt: record.closedAt.flatMap { dateFormatter.date(from: $0) },
            settledAt: record.settledAt.flatMap { dateFormatter.date(from: $0) },
            lastSyncedAt: Date(),
            needsSync: false
        )
    }

    /// Convert entity back to API model for display
    func toTradeRecord() -> TradeRecord {
        let dateFormatter = ISO8601DateFormatter()

        return TradeRecord(
            id: Int(id) ?? 0,
            marketId: marketId,
            marketTitle: marketTitle,
            side: side,
            entryPrice: Double(entryPriceCents) / 100.0,
            exitPrice: exitPriceCents.map { Double($0) / 100.0 },
            quantity: quantity,
            status: status,
            thesis: thesis,
            probabilityEstimate: probabilityEstimate,
            edgePct: edgePct,
            emotionalState: emotionalState,
            createdAt: dateFormatter.string(from: createdAt),
            closedAt: closedAt.map { dateFormatter.string(from: $0) },
            settledAt: settledAt.map { dateFormatter.string(from: $0) },
            pnlCents: pnlCents
        )
    }
}

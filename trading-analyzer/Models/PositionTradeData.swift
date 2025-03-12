import Foundation

struct PositionTradeData: Identifiable {
    let id = UUID()
    let marketId: String
    let positionTradeIdx: Int
    let isBuy: Bool
    let expectedMarketTradeIdx: Int
    let actualMarketTradeIdx: Int
    let expectedBaseTokenAmount: Int64
    let expectedQuoteTokenAmount: Int64
    let actualBaseTokenAmount: Int64
    let actualQuoteTokenAmount: Int64
    let actualSlippage: Int
    let expectedPnl: Int64
    let expectedPnlRatio: Int
    let actualPnl: Int64
    let actualPnlRatio: Int
    let actionSummary: String
    let actionTriggerValue: Int
    let actionReason: String
    let confirmTime: Date

    // Computed property to get formatted amounts
    var formattedBaseAmount: String {
        return Double(actualBaseTokenAmount) / 1_000_000_000.0 > 1000
            ? String(format: "%.2fK", Double(actualBaseTokenAmount) / 1_000_000_000_000.0)
            : String(format: "%.4f", Double(actualBaseTokenAmount) / 1_000_000_000.0)
    }

    var formattedQuoteAmount: String {
        return String(format: "%.4f SOL", Double(actualQuoteTokenAmount) / 1_000_000_000.0)
    }

    var formattedPrice: String {
        let price = Double(actualQuoteTokenAmount) / Double(max(1, actualBaseTokenAmount))
        return String(format: "%.9f SOL", price)
    }

    var formattedPnl: String {
        let pnl = Double(actualPnl) / 1_000_000_000.0
        return String(format: "%.4f SOL", pnl)
    }

    var formattedPnlRatio: String {
        return String(format: "%.2f%%", Double(actualPnlRatio) / 100.0)
    }
}

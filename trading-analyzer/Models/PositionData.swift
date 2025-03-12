import Foundation

struct PositionData: Identifiable {
    let id: UUID
    let marketId: String
    let pnlRatio: Int
    let pnl: Int64
    let cost: Int64
    let maxProfitRatio: Int
    let maxProfit: Int64
    let maxLossRatio: Int
    let maxLoss: Int64
    let createTime: Date
    let updateTime: Date
}

// Extension for formatting values
extension Int64 {
    func lamportsToSol() -> Double {
        return Double(self) / 1_000_000_000.0
    }
}

extension Double {
    func formattedSol() -> String {
        return String(format: "%.4f SOL", self)
    }
}

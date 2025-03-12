//
//  CSVParserService.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import Foundation
import SwiftCSV

class CSVParserService {
    static func parsePositionData(from url: URL) async throws -> [PositionData] {
        let csv = try CSV<Named>(url: url)

        var positions: [PositionData] = []

        for row in csv.rows {
            let marketId = row["market_id"] ?? ""
            let pnlRatio = Int(row["pnl_ratio"] ?? "0") ?? 0
            let pnl = Int(row["pnl"] ?? "0") ?? 0
            let cost = Int(row["cost"] ?? "0") ?? 0
            let isMarketLaunched = (row["is_market_launched"] ?? "false") == "true"
            let maxProfitRatio = Int(row["max_profit_ratio"] ?? "0") ?? 0
            let maxProfit = Int(row["max_profit"] ?? "0") ?? 0
            let maxLossRatio = Int(row["max_loss_ratio"] ?? "0") ?? 0
            let maxLoss = Int(row["max_loss"] ?? "0") ?? 0
            let createTime = row["create_time"] ?? ""
            let updateTime = row["update_time"] ?? ""

            let position = PositionData(
                marketId: marketId,
                pnlRatio: pnlRatio,
                pnl: pnl,
                cost: cost,
                isMarketLaunched: isMarketLaunched,
                maxProfitRatio: maxProfitRatio,
                maxProfit: maxProfit,
                maxLossRatio: maxLossRatio,
                maxLoss: maxLoss,
                createTime: createTime,
                updateTime: updateTime
            )

            positions.append(position)
        }

        return positions
    }
}

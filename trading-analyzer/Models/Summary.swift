//
//  Summary.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/21/25.
//

import Foundation

// Model to represent the JSON structure
struct TaskSummary: Codable, Hashable {
    let name: String
    let summaryTaskStatistic: SummaryTaskStatistic

    enum CodingKeys: String, CodingKey {
        case name
        case summaryTaskStatistic = "summary_task_statistic"
    }
}

// Main model for the summary statistics
struct SummaryTaskStatistic: Codable, Hashable {
    let collectTime: String
    let runningTime: String
    let pendingPositionCount: Int
    let successOpenedPositionCount: Int
    let finishedPositionCount: Int
    let profitablePositionCount: Int
    let losingPositionCount: Int
    let profitablePositionRatio: Double
    let profitableSellTradeRatio: Double
    let profitableSellTradeCount: Int
    let totalSellTradeCount: Int
    let successTxCount: Int
    let avgGasFeePerSuccessTx: Double
    let avgTipPerSuccessTx: Double
    let cumulativeQuoteTokenCostMap: [String: Double]
    let highestProfitByOneTradeMap: [String: Double]
    let highestProfitRatioByOneTradeMap: [String: Double]
    let totalGasFee: Double
    let totalTip: Double
    let launchedMarketPositionCount: Int
    let nativeTokenCumulativePnl: Double
    let cumulativePnlMap: [String: Double]
    let maxProfitMap: [String: Double]
    let maxLossMap: [String: Double]

    enum CodingKeys: String, CodingKey {
        case collectTime = "collect_time"
        case runningTime = "running_time"
        case pendingPositionCount = "pending_position_count"
        case successOpenedPositionCount = "success_opened_position_count"
        case finishedPositionCount = "finished_position_count"
        case profitablePositionCount = "profitable_position_count"
        case losingPositionCount = "losing_position_count"
        case profitablePositionRatio = "profitable_position_ratio"
        case profitableSellTradeRatio = "profitable_sell_trade_ratio"
        case profitableSellTradeCount = "profitable_sell_trade_count"
        case totalSellTradeCount = "total_sell_trade_count"
        case successTxCount = "success_tx_count"
        case avgGasFeePerSuccessTx = "avg_gas_fee_per_success_tx"
        case avgTipPerSuccessTx = "avg_tip_per_success_tx"
        case cumulativeQuoteTokenCostMap = "cumulative_quote_token_cost_map"
        case highestProfitByOneTradeMap = "highest_profit_by_one_trade_map"
        case highestProfitRatioByOneTradeMap = "highest_profit_ratio_by_one_trade_map"
        case totalGasFee = "total_gas_fee"
        case totalTip = "total_tip"
        case launchedMarketPositionCount = "launched_market_position_count"
        case nativeTokenCumulativePnl = "native_token_cumulative_pnl"
        case cumulativePnlMap = "cumulative_pnl_map"
        case maxProfitMap = "max_profit_map"
        case maxLossMap = "max_loss_map"
    }
}

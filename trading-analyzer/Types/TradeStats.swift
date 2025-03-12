//
//  TraderStats.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import Foundation

struct TradeStats: Decodable {
    let tradeTaskId: Int
    let collectTime: String
    let runningTime: Int
    let pendingPositionCount: Int
    let successOpenedPositionCount: Int
    let finishedPositionCount: Int
    let profitablePositionCount: Int
    let losingPositionCount: Int
    let profitablePositionRatio: Int
    let profitableSellTradeRatio: Int
    let profitableSellTradeCount: Int
    let totalSellTradeCount: Int
    let successTxCount: Int
    let notConfirmTxCount: Int
    let revertedTxCount: Int
    let avgGasFeePerSuccessTx: Int
    let avgGasFeePerTx: Int
    let avgTipPerSuccessTx: Int
    let currentQuoteTokenCostMap: [String: String]
    let cumulativeQuoteTokenCostMap: [String: String]
    let lowestQuoteTokenCostMap: [String: String]
    let highestProfitByOneTradeMap: [String: String]
    let highestProfitRatioByOneTradeMap: [String: Int]
    let totalGasFee: Int
    let totalTip: Int
    let nativeTokenCumulativePnl: Int
    let maxNativeTokenProfit: Int
    let maxNativeTokenLoss: Int
    let cumulativePnlMap: [String: String]
    let maxProfitMap: [String: String]
    let maxLossMap: [String: String]
    let launchedMarketPositionCount: Int
    let extra: [String: AnyCodable]
    let nativeQuoteTokenInfo: TokenInfo
    let quoteTokenInfoMap: [String: TokenInfo]

    enum CodingKeys: String, CodingKey {
        case tradeTaskId = "trade_task_id"
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
        case notConfirmTxCount = "not_confirm_tx_count"
        case revertedTxCount = "reverted_tx_count"
        case avgGasFeePerSuccessTx = "avg_gas_fee_per_success_tx"
        case avgGasFeePerTx = "avg_gas_fee_per_tx"
        case avgTipPerSuccessTx = "avg_tip_per_success_tx"
        case currentQuoteTokenCostMap = "current_quote_token_cost_map"
        case cumulativeQuoteTokenCostMap = "cumulative_quote_token_cost_map"
        case lowestQuoteTokenCostMap = "lowest_quote_token_cost_map"
        case highestProfitByOneTradeMap = "highest_profit_by_one_trade_map"
        case highestProfitRatioByOneTradeMap = "highest_profit_ratio_by_one_trade_map"
        case totalGasFee = "total_gas_fee"
        case totalTip = "total_tip"
        case nativeTokenCumulativePnl = "native_token_cumulative_pnl"
        case maxNativeTokenProfit = "max_native_token_profit"
        case maxNativeTokenLoss = "max_native_token_loss"
        case cumulativePnlMap = "cumulative_pnl_map"
        case maxProfitMap = "max_profit_map"
        case maxLossMap = "max_loss_map"
        case launchedMarketPositionCount = "launched_market_position_count"
        case extra
        case nativeQuoteTokenInfo = "native_quote_token_info"
        case quoteTokenInfoMap = "quote_token_info_map"
    }
}

struct TokenInfo: Decodable {
    let addr: String
    let alias: String
    let symbol: String
    let decimals: Int

    enum CodingKeys: String, CodingKey {
        case addr = "Addr"
        case alias = "Alias"
        case symbol = "Symbol"
        case decimals = "Decimals"
    }
}

// Helper struct to handle any JSON value type
struct AnyCodable: Decodable {
    let value: Any

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self.value = NSNull()
        } else if let bool = try? container.decode(Bool.self) {
            self.value = bool
        } else if let int = try? container.decode(Int.self) {
            self.value = int
        } else if let double = try? container.decode(Double.self) {
            self.value = double
        } else if let string = try? container.decode(String.self) {
            self.value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            self.value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            self.value = dictionary.mapValues { $0.value }
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "AnyCodable cannot decode value"
            )
        }
    }
}

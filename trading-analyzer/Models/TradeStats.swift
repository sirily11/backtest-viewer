import Foundation

struct TokenInfo: Codable {
    let Addr: String
    let Alias: String
    let Symbol: String
    let Decimals: Int

    var alias: String { Alias }
    var symbol: String { Symbol }
    var decimals: Int { Decimals }
}

struct TradeStats: Codable {
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
    let avgGasFeePerSuccessTx: Int64
    let avgGasFeePerTx: Int64
    let avgTipPerSuccessTx: Int64
    let currentQuoteTokenCostMap: [String: String]
    let cumulativeQuoteTokenCostMap: [String: String]
    let lowestQuoteTokenCostMap: [String: String]
    let highestProfitByOneTradeMap: [String: String]
    let highestProfitRatioByOneTradeMap: [String: Int]
    let totalGasFee: Int64
    let totalTip: Int64
    let nativeTokenCumulativePnl: Int64
    let maxNativeTokenProfit: Int64
    let maxNativeTokenLoss: Int64
    let cumulativePnlMap: [String: String]
    let maxProfitMap: [String: String]
    let maxLossMap: [String: String]
    let launchedMarketPositionCount: Int
    let extra: [String: String]
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

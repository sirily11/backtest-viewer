//
//  CSVParserService.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import Foundation
import SwiftCSV

enum CSVParserError: Error {
    case fileNotFound
    case parsingError(String)
    case dateParsingError
}

class CSVParserService {
    static func parsePositionData(from url: URL) async throws -> [PositionData] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let csv = try CSV<Named>(url: url, delimiter: ",", loadColumns: true)

                var positions: [PositionData] = []

                for i in 0..<csv.rows.count {
                    let row = csv.rows[i]

                    guard let marketId = row["market_id"],
                          let pnlRatioStr = row["pnl_ratio"],
                          let pnlStr = row["pnl"],
                          let costStr = row["cost"],
                          let maxProfitRatioStr = row["max_profit_ratio"],
                          let maxProfitStr = row["max_profit"],
                          let maxLossRatioStr = row["max_loss_ratio"],
                          let maxLossStr = row["max_loss"],
                          let createTimeStr = row["create_time"],
                          let updateTimeStr = row["update_time"]
                    else {
                        continue
                    }

                    let dateFormatter = ISO8601DateFormatter()

                    guard let createTime = dateFormatter.date(from: createTimeStr),
                          let updateTime = dateFormatter.date(from: updateTimeStr)
                    else {
                        throw CSVParserError.dateParsingError
                    }

                    let position = PositionData(
                        id: UUID(),
                        marketId: marketId,
                        pnlRatio: Int(pnlRatioStr) ?? 0,
                        pnl: Int64(pnlStr) ?? 0,
                        cost: Int64(costStr) ?? 0,
                        maxProfitRatio: Int(maxProfitRatioStr) ?? 0,
                        maxProfit: Int64(maxProfitStr) ?? 0,
                        maxLossRatio: Int(maxLossRatioStr) ?? 0,
                        maxLoss: Int64(maxLossStr) ?? 0,
                        createTime: createTime,
                        updateTime: updateTime
                    )

                    positions.append(position)
                }

                continuation.resume(returning: positions)
            } catch {
                continuation.resume(
                    throwing: CSVParserError.parsingError(error.localizedDescription))
            }
        }
    }

    static func parsePositionTradeData(from url: URL) async throws -> [PositionTradeData] {
        return try await withCheckedThrowingContinuation { continuation in
            do {
                let csv = try CSV<Named>(url: url, delimiter: ",", loadColumns: true)

                var trades: [PositionTradeData] = []

                for i in 0..<csv.rows.count {
                    let row = csv.rows[i]

                    guard let marketId = row["market_id"],
                          let positionTradeIdxStr = row["position_trade_idx"],
                          let isBuyStr = row["is_buy"],
                          let expectedMarketTradeIdxStr = row["expected_market_trade_idx"],
                          let actualMarketTradeIdxStr = row["actual_market_trade_idx"],
                          let expectedBaseTokenAmountStr = row["expected_base_token_amount"],
                          let expectedQuoteTokenAmountStr = row["expected_quote_token_amount"],
                          let actualBaseTokenAmountStr = row["actual_base_token_amount"],
                          let actualQuoteTokenAmountStr = row["actual_quote_token_amount"],
                          let actualSlippageStr = row["actual_slippage"],
                          let expectedPnlStr = row["expected_pnl"],
                          let expectedPnlRatioStr = row["expected_pnl_ratio"],
                          let actualPnlStr = row["actual_pnl"],
                          let actualPnlRatioStr = row["actual_pnl_ratio"],
                          let actionSummary = row["action_summary"],
                          let actionTriggerValueStr = row["action_trigger_value"],
                          let actionReason = row["action_reason"],
                          let confirmTimeStr = row["confirm_time"]
                    else {
                        continue
                    }

                    let dateFormatter = ISO8601DateFormatter()

                    guard let confirmTime = dateFormatter.date(from: confirmTimeStr) else {
                        throw CSVParserError.dateParsingError
                    }

                    let trade = PositionTradeData(
                        marketId: marketId,
                        positionTradeIdx: Int(positionTradeIdxStr) ?? 0,
                        isBuy: isBuyStr.lowercased() == "true",
                        expectedMarketTradeIdx: Int(expectedMarketTradeIdxStr) ?? 0,
                        actualMarketTradeIdx: Int(actualMarketTradeIdxStr) ?? 0,
                        expectedBaseTokenAmount: Int64(expectedBaseTokenAmountStr) ?? 0,
                        expectedQuoteTokenAmount: Int64(expectedQuoteTokenAmountStr) ?? 0,
                        actualBaseTokenAmount: Int64(actualBaseTokenAmountStr) ?? 0,
                        actualQuoteTokenAmount: Int64(actualQuoteTokenAmountStr) ?? 0,
                        actualSlippage: Int(actualSlippageStr) ?? 0,
                        expectedPnl: Int64(expectedPnlStr) ?? 0,
                        expectedPnlRatio: Int(expectedPnlRatioStr) ?? 0,
                        actualPnl: Int64(actualPnlStr) ?? 0,
                        actualPnlRatio: Int(actualPnlRatioStr) ?? 0,
                        actionSummary: actionSummary,
                        actionTriggerValue: Int(actionTriggerValueStr) ?? 0,
                        actionReason: actionReason,
                        confirmTime: confirmTime
                    )

                    trades.append(trade)
                }

                continuation.resume(returning: trades)
            } catch {
                continuation.resume(
                    throwing: CSVParserError.parsingError(error.localizedDescription))
            }
        }
    }
}

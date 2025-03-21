import SwiftUI

struct TradeStatsView: View {
    let trade: TradeStats
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection

                Picker("Category", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Positions").tag(1)
                    Text("Gas").tag(2)
                }
                .pickerStyle(.menu)
                .padding(.horizontal)

                switch selectedTab {
                case 0:
                    VStack {
                        overviewSection
                        profitsSection
                    }
                case 1: positionsSection
                case 2: gasSection
                default: overviewSection
                }
            }
            .padding()
        }
        .navigationTitle("Trade Stats")
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Task ID: \(trade.tradeTaskId)")
                    .font(.headline)
                Spacer()
                Text(formattedDate)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack {
                Label("Runtime: \(formatDuration(trade.runningTime))", systemImage: "clock")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            Divider()
        }
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Overview")
                .font(.headline)

            VStack(spacing: 12) {
                statRow(title: "Success Transactions", value: "\(trade.successTxCount)")
                statRow(title: "Not Confirmed", value: "\(trade.notConfirmTxCount)")
                statRow(title: "Reverted", value: "\(trade.revertedTxCount)")
                statRow(title: "Finished Positions", value: "\(trade.finishedPositionCount)")
                statRow(title: "Pending Positions", value: "\(trade.pendingPositionCount)")

                Divider()

                Text("Winrate")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 4)

                statRow(
                    title: "Profitable Positions",
                    value: "\(trade.profitablePositionCount)/\(trade.finishedPositionCount)"
                )
                statRow(
                    title: "Position Winrate",
                    value: formatPercentage(trade.profitablePositionRatio),
                    valueColor: winrateColor(trade.profitablePositionRatio)
                )
                statRow(
                    title: "Sell Trade Winrate",
                    value: formatPercentage(trade.profitableSellTradeRatio),
                    valueColor: winrateColor(trade.profitableSellTradeRatio)
                )

                Divider()

                Text("Cumulative P&L")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 4)

                // Add native token P&L
                statRow(
                    title: "Native Token P&L",
                    value: formatTokenAmount(
                        "\(trade.nativeTokenCumulativePnl)", token: trade.nativeQuoteTokenInfo.alias
                    ),
                    valueColor: pnlColor("\(trade.nativeTokenCumulativePnl)")
                )

                // Add P&L for each token
                ForEach(Array(trade.cumulativePnlMap.keys).sorted(), id: \.self) { token in
                    if let pnl = trade.cumulativePnlMap[token] {
                        statRow(
                            title: "\(token.uppercased()) P&L",
                            value: formatTokenAmount(pnl, token: token),
                            valueColor: pnlColor(pnl)
                        )
                    }
                }

                Divider()

                ForEach(Array(trade.cumulativeQuoteTokenCostMap.keys).sorted(), id: \.self) {
                    token in
                    if let cost = trade.cumulativeQuoteTokenCostMap[token] {
                        statRow(
                            title: "Total \(token.uppercased()) Cost",
                            value: formatTokenAmount(cost, token: token)
                        )
                    }
                }
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var positionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Positions")
                .font(.headline)

            VStack(spacing: 12) {
                statRow(title: "Successfully Opened", value: "\(trade.successOpenedPositionCount)")
                statRow(title: "Finished", value: "\(trade.finishedPositionCount)")
                statRow(title: "Pending", value: "\(trade.pendingPositionCount)")
                statRow(title: "Launched Market", value: "\(trade.launchedMarketPositionCount)")

                Divider()

                statRow(title: "Profitable Positions", value: "\(trade.profitablePositionCount)")
                statRow(title: "Losing Positions", value: "\(trade.losingPositionCount)")
                statRow(
                    title: "Profitable Position Ratio",
                    value: "\(formatPercentage(trade.profitablePositionRatio))"
                )

                Divider()

                statRow(title: "Total Sell Trades", value: "\(trade.totalSellTradeCount)")
                statRow(title: "Profitable Sell Trades", value: "\(trade.profitableSellTradeCount)")
                statRow(
                    title: "Profitable Sell Trade Ratio",
                    value: "\(formatPercentage(trade.profitableSellTradeRatio))"
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var gasSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Gas & Fees")
                .font(.headline)

            VStack(spacing: 12) {
                statRow(
                    title: "Total Gas Fee",
                    value: formatTokenAmount(
                        "\(trade.totalGasFee)", token: trade.nativeQuoteTokenInfo.alias
                    )
                )
                statRow(
                    title: "Total Tip",
                    value: formatTokenAmount(
                        "\(trade.totalTip)", token: trade.nativeQuoteTokenInfo.alias
                    )
                )

                Divider()

                statRow(
                    title: "Avg Gas Fee (per success tx)",
                    value: formatTokenAmount(
                        "\(trade.avgGasFeePerSuccessTx)", token: trade.nativeQuoteTokenInfo.alias
                    )
                )
                statRow(
                    title: "Avg Gas Fee (all tx)",
                    value: formatTokenAmount(
                        "\(trade.avgGasFeePerTx)", token: trade.nativeQuoteTokenInfo.alias
                    )
                )
                statRow(
                    title: "Avg Tip (success tx)",
                    value: formatTokenAmount(
                        "\(trade.avgTipPerSuccessTx)", token: trade.nativeQuoteTokenInfo.alias
                    )
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private var profitsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Profits & Losses")
                .font(.headline)

            ForEach(Array(trade.cumulativePnlMap.keys).sorted(), id: \.self) { token in
                let symbolInfo = trade.quoteTokenInfoMap[token]
                let tokenSymbol = symbolInfo?.symbol ?? token.uppercased()

                VStack(alignment: .leading, spacing: 12) {
                    Text(tokenSymbol)
                        .font(.title3)
                        .fontWeight(.medium)

                    if let maxProfit = trade.maxProfitMap[token] {
                        statRow(
                            title: "Max Profit",
                            value: formatTokenAmount(maxProfit, token: token),
                            valueColor: pnlColor(maxProfit)
                        )
                    }

                    if let maxLoss = trade.maxLossMap[token] {
                        statRow(
                            title: "Max Loss",
                            value: formatTokenAmount(maxLoss, token: token),
                            valueColor: pnlColor(maxLoss)
                        )
                    }

                    if let highestProfit = trade.highestProfitByOneTradeMap[token] {
                        statRow(
                            title: "Highest Profit (Single Trade)",
                            value: formatTokenAmount(highestProfit, token: token),
                            valueColor: .green
                        )
                    }

                    if let highestRatio = trade.highestProfitRatioByOneTradeMap[token] {
                        statRow(
                            title: "Highest Profit Ratio",
                            value: formatPercentage(highestRatio),
                            valueColor: .green
                        )
                    }

                    Divider()

                    if let current = trade.currentQuoteTokenCostMap[token] {
                        statRow(
                            title: "Current Cost",
                            value: formatTokenAmount(current, token: token)
                        )
                    }

                    if let cumulative = trade.cumulativeQuoteTokenCostMap[token] {
                        statRow(
                            title: "Cumulative Cost",
                            value: formatTokenAmount(cumulative, token: token)
                        )
                    }

                    if let lowest = trade.lowestQuoteTokenCostMap[token] {
                        statRow(
                            title: "Lowest Cost",
                            value: formatTokenAmount(lowest, token: token)
                        )
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("Native Token Performance")
                    .font(.title3)
                    .fontWeight(.medium)

                statRow(
                    title: "Max Profit",
                    value: formatTokenAmount(
                        "\(trade.maxNativeTokenProfit)", token: trade.nativeQuoteTokenInfo.alias
                    ),
                    valueColor: pnlColor("\(trade.maxNativeTokenProfit)")
                )

                statRow(
                    title: "Max Loss",
                    value: formatTokenAmount(
                        "\(trade.maxNativeTokenLoss)", token: trade.nativeQuoteTokenInfo.alias
                    ),
                    valueColor: pnlColor("\(trade.maxNativeTokenLoss)")
                )
            }
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func statRow(title: String, value: String, valueColor: Color? = nil) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(valueColor)
                .fontWeight(.medium)
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        if let date = ISO8601DateFormatter().date(from: trade.collectTime) {
            return formatter.string(from: date)
        }
        return trade.collectTime
    }

    private func formatDuration(_ millionSeconds: Int) -> String {
        let seconds = Double(millionSeconds) / 1_000_000
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .abbreviated
        formatter.allowedUnits = [.day, .hour, .minute, .second]
        return formatter.string(from: seconds) ?? "0s"
    }

    private func formatTokenAmount(_ amount: String, token: String) -> String {
        let tokenInfo = trade.quoteTokenInfoMap[token] ?? trade.nativeQuoteTokenInfo
        let decimals = tokenInfo.decimals

        if let amountNum = Double(amount) {
            let adjustedAmount = amountNum / pow(10, Double(decimals))
            return String(format: "%.4f %@", adjustedAmount, tokenInfo.symbol)
        }
        return "\(amount) \(tokenInfo.symbol)"
    }

    private func formatPercentage(_ value: Int) -> String {
        let percentage = Double(value) / 100.0
        return String(format: "%.2f%%", percentage)
    }

    private func pnlColor(_ amount: String) -> Color {
        if let amountNum = Double(amount) {
            if amountNum > 0 {
                return .green
            } else if amountNum < 0 {
                return .red
            }
        }
        return .primary
    }

    private func winrateColor(_ ratio: Int) -> Color {
        if ratio > 5000 {
            return .green
        } else if ratio < 5000 {
            return .red
        } else {
            return .primary
        }
    }
}

// Helper for Double.pow since it's not directly available
private func pow(_ base: Double, _ exponent: Double) -> Double {
    return Darwin.pow(base, exponent)
}

struct TradeStatsView_Previews: PreviewProvider {
    static var previews: some View {
        // Sample data for preview
        let sampleJSON = """
            {
              "trade_task_id": 0,
              "collect_time": "2025-02-27T09:56:19+08:00",
              "running_time": 1056399000,
              "pending_position_count": 0,
              "success_opened_position_count": 4,
              "finished_position_count": 4,
              "profitable_position_count": 2,
              "losing_position_count": 2,
              "profitable_position_ratio": 5000,
              "profitable_sell_trade_ratio": 5000,
              "profitable_sell_trade_count": 2,
              "total_sell_trade_count": 4,
              "success_tx_count": 8,
              "not_confirm_tx_count": 0,
              "reverted_tx_count": 0,
              "avg_gas_fee_per_success_tx": 26999999,
              "avg_gas_fee_per_tx": 26999999,
              "avg_tip_per_success_tx": 27000000,
              "current_quote_token_cost_map": {
                "sol": "0"
              },
              "cumulative_quote_token_cost_map": {
                "sol": "1600000000"
              },
              "lowest_quote_token_cost_map": {
                "sol": "400000000"
              },
              "highest_profit_by_one_trade_map": {
                "sol": "121050258"
              },
              "highest_profit_ratio_by_one_trade_map": {
                "sol": 3026
              },
              "total_gas_fee": 215999992,
              "total_tip": 216000000,
              "native_token_cumulative_pnl": -276166132,
              "max_native_token_profit": 0,
              "max_native_token_loss": -297216391,
              "cumulative_pnl_map": {
                "sol": "155833860"
              },
              "max_profit_map": {
                "sol": "155833860"
              },
              "max_loss_map": {
                "sol": "-25156441"
              },
              "launched_market_position_count": 0,
              "extra": {},
              "native_quote_token_info": {
                "Addr": "0",
                "Alias": "sol",
                "Symbol": "SOL",
                "Decimals": 9
              },
              "quote_token_info_map": {
                "sol": {
                  "Addr": "0",
                  "Alias": "sol",
                  "Symbol": "SOL",
                  "Decimals": 9
                }
              }
            }
            """

        let decoder = JSONDecoder()
        let sampleStats = try! decoder.decode(TradeStats.self, from: sampleJSON.data(using: .utf8)!)

        TradeStatsView(trade: sampleStats)
    }
}

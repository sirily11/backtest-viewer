//
//  SummaryView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/21/25.
//

import SwiftUI

struct SummaryView: View {
    @Environment(AlertManager.self) var alertManager
    @State var summaries: [TaskSummary] = []
    @State var selectedSummary: TaskSummary? = nil
    @State var isLoading = true

    let url: URL

    var body: some View {
        VStack {
            if !summaries.isEmpty {
                VStack {
                    if let selectedSummary = selectedSummary {
                        SummaryTaskStatisticView(statistic: selectedSummary.summaryTaskStatistic)
                            .padding()
                    } else {
                        Text("Select a summary to view details")
                            .foregroundColor(.secondary)
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Picker("Select Summary", selection: $selectedSummary) {
                            ForEach(summaries, id: \.name) { summary in
                                Text(summary.name).tag(summary as TaskSummary?)
                            }
                        }
                        .pickerStyle(.menu)
                        .padding()
                    }
                }
            } else {
                VStack(alignment: .center) {
                    Text("Loading Summary")
                        .font(.title)
                        .fontWeight(.bold)

                    ProgressView()
                        .padding()

                    Button("Reload") {
                        loadSummary()
                    }
                    .buttonStyle(.bordered)
                    .padding()
                }
            }
        }
        .onAppear {
            loadSummary()
        }
    }

    func loadSummary() {
        isLoading = true
        do {
            let data = try Data(contentsOf: url)
            let decodedSummaries = try JSONDecoder().decode([TaskSummary].self, from: data)

            DispatchQueue.main.async {
                withAnimation {
                    self.summaries = decodedSummaries
                    self.selectedSummary = decodedSummaries.first
                    self.isLoading = false
                }
            }
        } catch {
            print("Failed to load summary: \(error)")
            DispatchQueue.main.async {
                self.isLoading = false
                alertManager.showAlert(
                    message: "Failed to load summary: \(error.localizedDescription)")
            }
        }
    }
}

struct SummaryTaskStatisticView: View {
    let statistic: SummaryTaskStatistic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header with card design
                headerCard

                // Position Statistics
                statisticsCard(title: "Position Statistics") {
                    positionContent
                }

                // Trading Statistics
                statisticsCard(title: "Trading Statistics") {
                    tradingContent
                }

                // Gas and Transaction Costs
                statisticsCard(title: "Gas & Transaction Costs") {
                    gasContent
                }

                // Token-specific PnL Statistics
                statisticsCard(title: "Profit & Loss") {
                    tokenPnLContent
                }
            }
            .padding()
        }
        .navigationTitle("Trading Summary")
    }

    // MARK: - Card Container

    private func statisticsCard<Content: View>(title: String, @ViewBuilder content: () -> Content)
        -> some View
    {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.bottom, 4)

            content()
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Header Section

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary Statistics")
                .font(.title)
                .fontWeight(.bold)

            HStack {
                VStack(alignment: .leading) {
                    Text("Collected at")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(statistic.collectTime)
                        .fontWeight(.medium)
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Running time")
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text(statistic.runningTime)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Position Section

    private var positionContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Position counts
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    metricView(label: "Pending Positions", value: "\(statistic.pendingPositionCount)")
                    metricView(
                        label: "Opened Positions", value: "\(statistic.successOpenedPositionCount)")
                    metricView(label: "Finished Positions", value: "\(statistic.finishedPositionCount)")
                    metricView(
                        label: "Launched Markets", value: "\(statistic.launchedMarketPositionCount)")
                }

            Divider()

            // Position performance
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profitable")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(statistic.profitablePositionCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Losing")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(statistic.losingPositionCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                }

                Spacer()

                // Ratio indicator
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Win Ratio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", statistic.profitablePositionRatio * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(statistic.profitablePositionRatio >= 0.5 ? .green : .red)
                }
            }
        }
    }

    // MARK: - Trading Section

    private var tradingContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Successful Trades")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(statistic.successTxCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Total Sell Trades")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(statistic.totalSellTradeCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Profitable Sells")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(statistic.profitableSellTradeCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Sell Win Ratio")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", statistic.profitableSellTradeRatio * 100))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(statistic.profitableSellTradeRatio >= 0.5 ? .green : .red)
                }
            }
        }
    }

    // MARK: - Gas Section

    private var gasContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 16) {
                    metricView(
                        label: "Avg Gas Fee",
                        value: String(format: "%.4f", statistic.avgGasFeePerSuccessTx))
                    metricView(
                        label: "Avg Tip", value: String(format: "%.4f", statistic.avgTipPerSuccessTx))
                    metricView(
                        label: "Total Gas Fee", value: String(format: "%.4f", statistic.totalGasFee))
                    metricView(label: "Total Tip", value: String(format: "%.4f", statistic.totalTip))
                }

            // Token costs
            if !statistic.cumulativeQuoteTokenCostMap.isEmpty {
                Divider()

                Text("Costs by Token")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.top, 4)

                ForEach(
                    statistic.cumulativeQuoteTokenCostMap.sorted(by: { $0.value > $1.value }),
                    id: \.key)
                { token, cost in
                    HStack {
                        Text(token)
                            .font(.body)
                        Spacer()
                        Text(String(format: "%.4f", cost))
                            .font(.body)
                            .fontWeight(.medium)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
    }

    // MARK: - Token PnL Section

    private var tokenPnLContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Native token PnL
            HStack {
                Text("Native Token P&L")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "%.4f", statistic.nativeTokenCumulativePnl))
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(statistic.nativeTokenCumulativePnl >= 0 ? .green : .red)
            }

            // Cumulative PnL by token
            if !statistic.cumulativePnlMap.isEmpty {
                Divider()

                Text("Cumulative P&L by Token")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.vertical, 4)

                ForEach(statistic.cumulativePnlMap.sorted(by: { $0.value > $1.value }), id: \.key) {
                    token, pnl in
                    HStack {
                        Text(token)
                            .font(.body)
                        Spacer()
                        Text(String(format: "%.4f", pnl))
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(pnl >= 0 ? .green : .red)
                    }
                    .padding(.vertical, 4)
                }
            }

            // Best and worst trades
            if !statistic.highestProfitByOneTradeMap.isEmpty {
                Divider()

                Text("Best & Worst Trades")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .padding(.vertical, 4)

                ForEach(
                    statistic.highestProfitByOneTradeMap.sorted(by: { $0.value > $1.value }),
                    id: \.key)
                { token, profit in
                    VStack(spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading) {
                                Text(token)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Text("Best Trade")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            VStack(alignment: .trailing) {
                                Text(String(format: "%.4f", profit))
                                    .font(.body)
                                    .fontWeight(.bold)
                                    .foregroundColor(.green)

                                if let ratio = statistic.highestProfitRatioByOneTradeMap[token] {
                                    Text(String(format: "+%.1f%%", ratio * 100))
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                        }

                        if let maxLoss = statistic.maxLossMap[token] {
                            HStack(alignment: .top) {
                                Text("Worst Trade")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                Text(String(format: "%.4f", maxLoss))
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                        }

                        if token
                            != statistic.highestProfitByOneTradeMap.sorted(by: {
                                $0.value > $1.value
                            }).last?.key
                        {
                            Divider()
                                .padding(.vertical, 4)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func metricView(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

import SwiftUI

struct PositionLoadingView: View {
    let position: PositionData?
    let trades: [PositionTradeData]
    let priceData: [PriceData]

    var body: some View {
        if let position = position {
            PositionDetailView(position: position, trades: trades, priceData: priceData)
        } else {
            ProgressView()
        }
    }
}

struct PositionDetailView: View {
    let position: PositionData
    let trades: [PositionTradeData]
    let priceData: [PriceData]
    @Environment(\.dismiss) var dismiss

    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            headerView

            Picker("View", selection: $selectedTab) {
                Text("Overview").tag(0)
                Text("Trades").tag(1)
                Text("Chart").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()

            switch selectedTab {
            case 0:
                overviewView
            case 1:
                tradesView
            case 2:
                chartView
            default:
                EmptyView()
            }
        }
        .navigationTitle("Position Details")
    }

    private var headerView: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.gray)
                }
                .buttonBorderShape(.circle)
            }
            HStack {
                Text(position.marketId)
                    .textSelection(.enabled)
                    .font(.system(.headline, design: .monospaced))
                    .lineLimit(1)

                Spacer()

                Text(
                    position.createTime.formatted(
                        .dateTime.year().month().day().hour().minute().second())
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("PnL")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(position.pnl.lamportsToSol().formattedSol())
                        .font(.headline)
                        .foregroundStyle(position.pnl >= 0 ? .green : .red)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("PnL Ratio")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("\(position.pnlRatio / 100)%")
                        .font(.headline)
                        .foregroundStyle(position.pnlRatio >= 0 ? .green : .red)
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("Cost")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(position.cost.lamportsToSol().formattedSol())
                        .font(.headline)
                }
            }

            Divider()
        }
        .padding()
    }

    private var overviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Group {
                Text("Position Summary")
                    .font(.headline)

                VStack(spacing: 12) {
                    statRow(
                        title: "PnL", value: position.pnl.lamportsToSol().formattedSol(),
                        valueColor: position.pnl >= 0 ? .green : .red)
                    statRow(
                        title: "PnL Ratio", value: "\(Double(position.pnlRatio) / 100.0)%",
                        valueColor: position.pnlRatio >= 0 ? .green : .red)
                    statRow(title: "Cost", value: position.cost.lamportsToSol().formattedSol())

                    Divider()

                    statRow(
                        title: "Max Profit",
                        value: position.maxProfit.lamportsToSol().formattedSol(),
                        valueColor: .green)
                    statRow(
                        title: "Max Profit Ratio",
                        value: "\(Double(position.maxProfitRatio) / 100.0)%", valueColor: .green)

                    Divider()

                    statRow(
                        title: "Max Loss",
                        value: position.maxLoss.lamportsToSol().formattedSol(), valueColor: .red)
                    statRow(
                        title: "Max Loss Ratio",
                        value: "\(Double(position.maxLossRatio) / 100.0)%", valueColor: .red)

                    Divider()

                    statRow(
                        title: "Created",
                        value: position.createTime.formatted(
                            date: .abbreviated, time: .shortened))
                    statRow(
                        title: "Updated",
                        value: position.updateTime.formatted(
                            date: .abbreviated, time: .shortened))
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }

            Group {
                Text("Trade Statistics")
                    .font(.headline)

                VStack(spacing: 12) {
                    statRow(title: "Total Trades", value: "\(trades.count)")
                    statRow(title: "Buy Trades", value: "\(trades.filter { $0.isBuy }.count)")
                    statRow(title: "Sell Trades", value: "\(trades.filter { !$0.isBuy }.count)")

                    if !trades.filter({ !$0.isBuy }).isEmpty {
                        Divider()

                        let profitableTrades = trades.filter { !$0.isBuy && $0.actualPnl > 0 }
                        let profitableRatio =
                            Double(profitableTrades.count)
                                / Double(trades.filter { !$0.isBuy }.count) * 100.0

                        statRow(title: "Profitable Sells", value: "\(profitableTrades.count)")
                        statRow(
                            title: "Profitable Ratio",
                            value: String(format: "%.2f%%", profitableRatio),
                            valueColor: profitableRatio >= 50 ? .green : .red)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
    }

    private var tradesView: some View {
        ForEach(trades.sorted(by: { $0.confirmTime < $1.confirmTime })) { trade in
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(trade.isBuy ? "Buy" : "Sell")
                        .font(.headline)
                        .foregroundStyle(trade.isBuy ? .green : .red)

                    Spacer()

                    Text(trade.confirmTime, format: .dateTime)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text("Action: \(trade.actionSummary)")
                    .font(.subheadline)

                Text("Reason: \(trade.actionReason)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack {
                    VStack(alignment: .leading) {
                        Text("Amount")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trade.formattedBaseAmount)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Price")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trade.formattedPrice)
                    }

                    Spacer()

                    VStack(alignment: .leading) {
                        Text("Value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(trade.formattedQuoteAmount)
                    }
                }

                if !trade.isBuy {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("PnL")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(trade.formattedPnl)
                                .foregroundStyle(trade.actualPnl > 0 ? .green : .red)
                        }

                        Spacer()

                        VStack(alignment: .leading) {
                            Text("PnL Ratio")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(trade.formattedPnlRatio)
                                .foregroundStyle(trade.actualPnlRatio > 0 ? .green : .red)
                        }
                    }
                }
            }
            .padding()
        }
    }

    private var chartView: some View {
        PriceChartView(priceData: priceData, trades: trades)
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
}

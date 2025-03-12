import Charts
import SwiftUI

struct PriceChartView: View {
    let priceData: [PriceData]
    let trades: [PositionTradeData]

    @State private var selectedTrade: PositionTradeData?
    @State private var selectedPrice: PriceData?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Chart")
                .font(.headline)

            if priceData.isEmpty {
                Text("No price data available")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            } else {
                chartView

                if let selectedTrade = selectedTrade {
                    tradeDetailView(trade: selectedTrade)
                } else if let selectedPrice = selectedPrice {
                    priceDetailView(price: selectedPrice)
                }
            }
        }
        .padding()
    }

    private var chartView: some View {
        Chart {
            // Price line
            ForEach(priceData) { price in
                LineMark(
                    x: .value("Time", price.timeSecond),
                    y: .value("Price", price.avgPriceInSol)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)
            }

            // Price range area
            ForEach(priceData) { price in
                AreaMark(
                    x: .value("Time", price.timeSecond),
                    yStart: .value("Min", price.minPriceInSol),
                    yEnd: .value("Max", price.maxPriceInSol)
                )
                .foregroundStyle(.blue.opacity(0.1))
            }

            // Buy trades
            ForEach(trades.filter { $0.isBuy }) { trade in
                PointMark(
                    x: .value("Time", trade.confirmTime),
                    y: .value("Price", calculateTradePrice(trade))
                )
                .foregroundStyle(.green)
                .symbolSize(100)
            }

            // Sell trades
            ForEach(trades.filter { !$0.isBuy }) { trade in
                PointMark(
                    x: .value("Time", trade.confirmTime),
                    y: .value("Price", calculateTradePrice(trade))
                )
                .foregroundStyle(.red)
                .symbolSize(100)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { _ in
                AxisGridLine()
                AxisTick()
                AxisValueLabel(format: .dateTime.hour().minute())
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine()
                AxisTick()
            }
        }
        .frame(height: 300)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let x = value.location.x - geometry[proxy.plotAreaFrame].origin.x
                                let y = value.location.y - geometry[proxy.plotAreaFrame].origin.y

                                if let date = proxy.value(atX: x, as: Date.self),
                                   let price = proxy.value(atY: y, as: Double.self)
                                {
                                    // Find closest price data point
                                    if let closestPrice = findClosestPriceData(to: date) {
                                        selectedPrice = closestPrice
                                    }

                                    // Find closest trade
                                    if let closestTrade = findClosestTrade(to: date, price: price) {
                                        selectedTrade = closestTrade
                                    } else {
                                        selectedTrade = nil
                                    }
                                }
                            }
                    )
            }
        }
    }

    private func tradeDetailView(trade: PositionTradeData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(trade.isBuy ? "Buy" : "Sell")
                    .font(.headline)
                    .foregroundStyle(trade.isBuy ? .green : .red)

                Spacer()

                Text(trade.confirmTime, format: .dateTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

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
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    private func priceDetailView(price: PriceData) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Price Data")
                    .font(.headline)

                Spacer()

                Text(price.timeSecond, format: .dateTime)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                VStack(alignment: .leading) {
                    Text("Avg Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.9f SOL", price.avgPriceInSol))
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("Min Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.9f SOL", price.minPriceInSol))
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("Max Price")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(String(format: "%.9f SOL", price.maxPriceInSol))
                }
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Transactions")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(price.transactionCount)")
                }
            }
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }

    // Helper functions
    private func calculateTradePrice(_ trade: PositionTradeData) -> Double {
        return Double(trade.actualQuoteTokenAmount) / Double(max(1, trade.actualBaseTokenAmount))
    }

    private func findClosestPriceData(to date: Date) -> PriceData? {
        guard !priceData.isEmpty else { return nil }

        return priceData.min(by: {
            abs($0.timeSecond.timeIntervalSince(date)) < abs($1.timeSecond.timeIntervalSince(date))
        })
    }

    private func findClosestTrade(to date: Date, price: Double) -> PositionTradeData? {
        guard !trades.isEmpty else { return nil }

        // First filter trades that are close in time (within 5 minutes)
        let closeTimeThreshold = 5 * 60.0 // 5 minutes in seconds
        let closeInTime = trades.filter {
            abs($0.confirmTime.timeIntervalSince(date)) < closeTimeThreshold
        }

        if closeInTime.isEmpty {
            return nil
        }

        // Then find the closest in price among those
        return closeInTime.min(by: {
            abs(calculateTradePrice($0) - price) < abs(calculateTradePrice($1) - price)
        })
    }
}

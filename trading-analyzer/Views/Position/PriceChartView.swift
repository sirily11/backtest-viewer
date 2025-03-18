import Charts
import Shimmer
import SwiftUI

struct PriceChartView: View {
    let marketId: String
    let trades: [PositionTradeData]

    // Add state for visible range
    @State private var visibleDateRange: ClosedRange<Date>?
    @State private var priceData = [PriceOrTrade]()
    @Environment(\.openWindow) var openWindow
    @Environment(DuckDBService.self) var duckDBService
    @Environment(AlertManager.self) var alertManager

    @State var selectedIndex: Int?
    @State var scale: Double = 1
    @State var isLoading = true

    /**
     Calculate the visible range base on the visible date range
     */
    private var visibleRange: ClosedRange<Int>? {
        guard let dateRange = visibleDateRange, !priceData.isEmpty else { return nil }

        // Find the indices that correspond to the date range bounds
        let lowerIndex = findClosestPriceDataIndex(to: dateRange.lowerBound) ?? 0
        let upperIndex =
            findClosestPriceDataIndex(to: dateRange.upperBound) ?? (priceData.count - 1)

        // Ensure we have a valid range (lower <= upper)
        return min(lowerIndex, upperIndex)...max(lowerIndex, upperIndex)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Chart")
                .font(.headline)

            // Add zoom controls
            HStack {
                Button(action: {
                    resetZoom()
                }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.caption)
                }

                Spacer()

                Button(action: {
                    zoomIn()
                }) {
                    Label("Zoom In", systemImage: "plus.magnifyingglass")
                        .font(.caption)
                }

                Button(action: {
                    zoomOut()
                }) {
                    Label("Zoom Out", systemImage: "minus.magnifyingglass")
                        .font(.caption)
                }
            }
            .padding(.bottom, 4)

            // Add legend
            HStack(spacing: 16) {
                // Price area legend
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.blue.opacity(0.3))
                        .frame(width: 16, height: 16)
                        .overlay(
                            Rectangle()
                                .stroke(.blue, lineWidth: 2)
                                .frame(width: 16, height: 2)
                                .offset(y: -7)
                        )
                    Text("Avg Price")
                        .font(.caption)
                }

                // Price range legend
                HStack(spacing: 4) {
                    Rectangle()
                        .fill(.blue.opacity(0.1))
                        .frame(width: 16, height: 8)
                        .overlay(
                            Rectangle()
                                .stroke(.blue.opacity(0.5), lineWidth: 1)
                        )
                    Text("Price Range")
                        .font(.caption)
                }

                // Selected point legend
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                    Text("Selected")
                        .font(.caption)
                }

                // Buy trade legend
                HStack(spacing: 4) {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                    Text("Buy")
                        .font(.caption)
                }

                // Sell trade legend
                HStack(spacing: 4) {
                    Circle()
                        .fill(.red)
                        .frame(width: 8, height: 8)
                    Text("Sell")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 8)

            if priceData.isEmpty {
                if isLoading {
                    HStack {
                        Spacer()
                        Text("Loading price data...")
                            .font(.title2)
                            .shimmering()
                        Spacer()
                    }
                } else {
                    VStack {
                        Text("No price data available, check your database connection.")
                            .frame(maxWidth: .infinity, alignment: .center)
                        Button("Open Settings") {
                            openWindow(id: "settings")
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.4))
                    .cornerRadius(8)
                }
            } else {
                chartView
            }
        }
        .padding()
        .onAppear {
            setInitialDateRange()
        }
        .onChange(of: visibleDateRange) { _, newRange in
            if let newRange = newRange, !priceData.isEmpty {
                Task {
                    do {
                        try await fetchPriceData(
                            startDate: newRange.lowerBound, endDate: newRange.upperBound
                        )
                    } catch {
                        alertManager.showAlert(message: error.localizedDescription)
                    }
                }
            }
        }
    }

    private var chartView: some View {
        ZStack(alignment: .topLeading) {
            Chart {
                // Price area chart with line
                ForEach(Array(priceData.enumerated()), id: \.offset) { index, element in
                    switch element {
                    case .price(let price):
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Price", price.avgPriceInSol)
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                        AreaMark(
                            x: .value("Index", index),
                            y: .value("Price", price.avgPriceInSol)
                        )
                        .foregroundStyle(.blue.opacity(0.6))

                    case .trade(let trade):

                        PointMark(
                            x: .value("Index", index),
                            y: .value("Price", calculateTradePrice(trade))
                        )
                        .symbolSize(100)
                        .foregroundStyle(trade.isBuy ? .green : .red)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))
                    }
                }
                if let selectedIndex = selectedIndex, selectedIndex < priceData.count {
                    RuleMark(
                        x: .value("Index", selectedIndex)
                    )
                    .foregroundStyle(Color.gray.opacity(0.2))
                    .zIndex(-1)
                    .annotation(
                        position: .top, spacing: 0,
                        overflowResolution: .init(
                            x: .fit(to: .chart),
                            y: .disabled
                        )
                    ) {
                        switch priceData[selectedIndex] {
                        case .price(let price):
                            PriceTooltipView(price: price)
                        case .trade(let trade):
                            TooltipView(trade: trade)
                        }
                    }
                }
            }
            .chartXSelection(value: $selectedIndex)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel {
                        if let index = value.as(Int.self),
                           index >= 0 && index < priceData.count
                        {
                            Text(timeFormatter.string(from: priceData[index].price?.timeSecond ?? Date()))
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartXScale(domain: visibleRange ?? 0...0) // Default to 0 range if no data
            .frame(height: 300)
        }
    }

    // Time formatter for x-axis labels
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }
}

// MARK: Fetch data on the fly

extension PriceChartView {
    func fetchPriceData(startDate: Date, endDate: Date) async throws {
        let data = try await duckDBService.fetchPriceData(
            forMarketId: marketId, start: startDate, end: endDate,
            interval: .initFromScale(scale: scale)
        )

        // get trades indexes by price data
        let tradesIndexes = trades.map { trade in
            findClosestPriceDataIndex(prices: data, to: trade.confirmTime)
        }
        // Create a new array to hold the merged result
        var mergedData: [PriceOrTrade] = []
        var currentTradeIndex = 0

        // Iterate through the original price data
        for (index, price) in data.enumerated() {
            // Check if there's a trade at this index
            if tradesIndexes.contains(index) {
                // Find all trades that correspond to this index
                while currentTradeIndex < tradesIndexes.count, tradesIndexes[currentTradeIndex] == index {
                    // Create a TradeWithPrice object combining the trade and price
                    let trade = trades[currentTradeIndex]

                    mergedData.append(.trade(trade: trade))
                    currentTradeIndex += 1
                }
            }

            // Add the original price data
            mergedData.append(.price(price: price))
        }

        priceData = mergedData
    }
}

// MARK: - Zoom and Pan Extensions

extension PriceChartView {
    func setInitialDateRange() {
        guard !trades.isEmpty else { return }

        // Find first and last trade times
        if let firstTradeTime = trades.map({ $0.confirmTime }).min(),
           let lastTradeTime = trades.map({ $0.confirmTime }).max()
        {
            // Add some padding (20% on each side)
            let timeSpan = lastTradeTime.timeIntervalSince(firstTradeTime)
            let padding = timeSpan * 0.2

            let startDate = firstTradeTime.addingTimeInterval(-padding)
            let endDate = lastTradeTime.addingTimeInterval(padding)

            // Set the initial date range
            visibleDateRange = startDate...endDate

            // Fetch data with this date range
            Task {
                do {
                    isLoading = true
                    try await fetchPriceData(startDate: startDate, endDate: endDate)
                    resetZoom()
                    try? await Task.sleep(nanoseconds: 500_000_000)
                    withAnimation {
                        isLoading = false
                    }

                } catch {
                    alertManager.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    func resetZoom() {
        if !priceData.isEmpty {
            if let firstDate = priceData.first(where: { $0.price?.timeSecond != nil })?.price?.timeSecond,
               let lastDate = priceData.last(where: { $0.price?.timeSecond != nil })?.price?.timeSecond
            {
                visibleDateRange = firstDate...lastDate
            }

        } else {
            visibleDateRange = nil
        }
    }

    /**
     Update the visibleDateRange base on the current scale
     */
    func zoomIn() {
        guard let visibleDateRange = visibleDateRange, scale >= 1 else { return }
        scale *= 0.8
        self.visibleDateRange = visibleDateRange.scale(to: 0.8)
    }

    /** xrin
     Update the visibleDateRange base on the current scale
     */
    func zoomOut() {
        guard let visibleDateRange = visibleDateRange, scale < 60 else { return }
        scale *= 1.2
        self.visibleDateRange = visibleDateRange.scale(to: 1.2)
    }
}

// MARK: - Data Helper Extensions

extension PriceChartView {
    func calculateTradePrice(_ trade: PositionTradeData) -> Double {
        return Double(trade.actualQuoteTokenAmount) / Double(max(1, trade.actualBaseTokenAmount))
    }

    func findClosestPriceDataIndex(to date: Date) -> Int? {
        guard !priceData.isEmpty else { return nil }

        return priceData.indices.min(by: { index1, index2 in
            let time1 = priceData[index1].price?.timeSecond
            let time2 = priceData[index2].price?.timeSecond
            guard let time1 = time1, let time2 = time2 else { return false }
            return abs(time1.timeIntervalSince(date)) < abs(time2.timeIntervalSince(date))
        })
    }

    func findClosestPriceDataIndex(prices: [PriceData], to date: Date) -> Int? {
        return prices.indices.min(by: { index1, index2 in
            let time1 = prices[index1].timeSecond
            let time2 = prices[index2].timeSecond
            return abs(time1.timeIntervalSince(date)) < abs(time2.timeIntervalSince(date))
        })
    }
}

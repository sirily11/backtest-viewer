import Charts
import SwiftUI

struct PriceChartView: View {
    let marketId: String
    let trades: [PositionTradeData]

    // Add state for visible range
    @State private var visibleDateRange: ClosedRange<Date>?
    @State private var priceData = [PriceData]()
    @State private var selectedInterval: PriceDataInterval = .oneMinute
    @Environment(\.openWindow) var openWindow
    @Environment(DuckDBService.self) var duckDBService
    @Environment(AlertManager.self) var alertManager

    @State var selectedIndex: Int?
    @State var scale: Double = 1

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

    private func isDateInRange(_ date: Date) -> Bool {
        guard let range = visibleRange, !priceData.isEmpty else { return true }
        // Find the nearest index to this date
        if let index = findClosestPriceDataIndex(to: date),
           range.contains(index)
        {
            return true
        }
        return false
    }

    private var selectedPrice: PriceData? {
        guard let index = selectedIndex,
              index >= 0 && index < priceData.count
        else {
            return nil
        }
        return priceData[index]
    }

    private var selectedTrade: PositionTradeData? {
        guard let selectedPrice = selectedPrice else { return nil }
        return findClosestTrade(to: selectedPrice.timeSecond)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Price Chart")
                .font(.headline)

            // Interval selector
            HStack {
                Text("Interval:")
                    .font(.caption)
                Picker("", selection: $selectedInterval) {
                    ForEach(PriceDataInterval.allCases, id: \.self) { interval in
                        Text(interval.displayName).tag(interval)
                    }
                }
                .pickerStyle(.segmented)
                .onChange(of: selectedInterval) { _, _ in
                    if let dateRange = visibleDateRange {
                        Task {
                            do {
                                try await fetchPriceData(
                                    startDate: dateRange.lowerBound,
                                    endDate: dateRange.upperBound
                                )
                            } catch {
                                alertManager.showAlert(message: error.localizedDescription)
                            }
                        }
                    }
                }
            }

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
            } else {
                chartView
            }
        }
        .padding()
        .onAppear {
            setInitialDateRange()
        }
        .task {
            do {
                try await fetchPriceData(
                    startDate: visibleDateRange?.lowerBound ?? Date(),
                    endDate: visibleDateRange?.upperBound ?? Date()
                )
            } catch {
                alertManager.showAlert(message: error.localizedDescription)
            }
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
                ForEach(Array(priceData.enumerated()), id: \.element.id) { index, price in
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
                }

                // Buy trades
                ForEach(trades.filter { $0.isBuy }) { trade in
                    if isDateInRange(trade.confirmTime),
                       let index = findClosestPriceDataIndex(to: trade.confirmTime)
                    {
                        PointMark(
                            x: .value("Index", index),
                            y: .value("Price", calculateTradePrice(trade))
                        )
                        .foregroundStyle(.green)
                        .symbolSize(100)
                    }
                }

                // Sell trades
                ForEach(trades.filter { !$0.isBuy }) { trade in
                    if isDateInRange(trade.confirmTime),
                       let index = findClosestPriceDataIndex(to: trade.confirmTime)
                    {
                        PointMark(
                            x: .value("Index", index),
                            y: .value("Price", calculateTradePrice(trade))
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
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
                        if let selectedTrade,
                           isVeryCloseToTrade(
                               date: priceData[selectedIndex].timeSecond, trade: selectedTrade
                           )
                        {
                            TooltipView(trade: selectedTrade)
                        } else if selectedIndex < priceData.count {
                            PriceTooltipView(price: priceData[selectedIndex])
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
                            Text(timeFormatter.string(from: priceData[index].timeSecond))
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
            interval: selectedInterval
        )
        priceData = data
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
                    try await fetchPriceData(startDate: startDate, endDate: endDate)

                } catch {
                    alertManager.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    func resetZoom() {
        if !priceData.isEmpty {
            let firstDate = priceData.first!.timeSecond
            let lastDate = priceData.last!.timeSecond
            visibleDateRange = firstDate...lastDate

        } else {
            visibleDateRange = nil
        }
    }

    /**
     Update the visibleDateRange base on the current scale
     */
    func zoomIn() {
        guard let visibleDateRange = visibleDateRange else { return }
        scale *= 0.8
        self.visibleDateRange = visibleDateRange.scale(to: 0.8)
    }

    /**
     Update the visibleDateRange base on the current scale
     */
    func zoomOut() {
        guard let visibleDateRange = visibleDateRange else { return }
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
            let time1 = priceData[index1].timeSecond
            let time2 = priceData[index2].timeSecond
            return abs(time1.timeIntervalSince(date)) < abs(time2.timeIntervalSince(date))
        })
    }
}

// MARK: - Chart Interaction Extensions

extension PriceChartView {
    // Enhanced version to detect if we're hovering over a trade point
    func findClosestTrade(
        to date: Date
    ) -> PositionTradeData? {
        guard !trades.isEmpty else { return nil }

        // Find the closest trade
        let closestTrade = trades.min(by: {
            abs($0.confirmTime.timeIntervalSince(date))
                < abs($1.confirmTime.timeIntervalSince(date))
        })

        // Check if the closest trade is within a reasonable time threshold
        // If the time difference is more than 5 seconds, return nil
        if let trade = closestTrade,
           abs(trade.confirmTime.timeIntervalSince(date)) <= 5
        {
            return trade
        }

        return nil
    }

    // Helper function to determine if a date is very close to a trade
    func isVeryCloseToTrade(date: Date, trade: PositionTradeData) -> Bool {
        // Consider "very close" to be within 1 second
        return abs(date.timeIntervalSince(trade.confirmTime)) < 1.0
    }
}

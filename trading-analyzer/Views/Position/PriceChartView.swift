import Charts
import SwiftUI

struct PriceChartView: View {
    let priceData: [PriceData]
    let trades: [PositionTradeData]

    // Add state for visible date range
    @State private var visibleDateRange: ClosedRange<Date>?
    @State private var initialZoomSet = false
    @State private var scale: CGFloat = 1.0
    @State private var dragOffset: CGFloat = 0.0
    @State private var lastDragValue: CGFloat = 0.0
    @Environment(\.openWindow) var openWindow

    @State var rawSelectedDate: Date?

    private func isDateInRange(_ date: Date) -> Bool {
        guard let range = visibleDateRange else { return true }
        return range.contains(date)
    }

    private var priceInRange: [PriceData] {
        priceData.filter { isDateInRange($0.timeSecond) }
    }

    private var selectedPrice: PriceData? {
        guard let rawDate = rawSelectedDate else { return nil }
        return findClosestPriceData(to: rawDate)
    }

    private var selectedTrade: PositionTradeData? {
        guard let rawDate = rawSelectedDate else { return nil }
        return findClosestTrade(to: rawDate)
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
                VStack {
                    Text("No price data available, check your database connection.")
                        .frame(maxWidth: .infinity, alignment: .center)
                    Button("Open Settings") {
                        openWindow(id: "settings")
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.8))
                .cornerRadius(8)
            } else {
                chartView
            }
        }
        .padding()
        .onAppear {
            setInitialDateRange()
        }
    }

    private var chartView: some View {
        ZStack(alignment: .topLeading) {
            Chart {
                // Price area chart with line
                ForEach(priceInRange) { price in
                    LineMark(
                        x: .value("Time", price.timeSecond),
                        y: .value("Price", price.avgPriceInSol)
                    )
                    .foregroundStyle(.blue)
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round))

                    AreaMark(x: .value("Time", price.timeSecond),
                             y: .value("Price", price.avgPriceInSol))
                        .foregroundStyle(.blue.opacity(0.6))
                }

                // Buy trades
                ForEach(trades.filter { $0.isBuy }) { trade in
                    if isDateInRange(trade.confirmTime) {
                        PointMark(
                            x: .value("Time", trade.confirmTime),
                            y: .value("Price", calculateTradePrice(trade))
                        )
                        .foregroundStyle(.green)
                        .symbolSize(100)
                    }
                }

                // Sell trades
                ForEach(trades.filter { !$0.isBuy }) { trade in
                    if isDateInRange(trade.confirmTime) {
                        PointMark(
                            x: .value("Time", trade.confirmTime),
                            y: .value("Price", calculateTradePrice(trade))
                        )
                        .foregroundStyle(.red)
                        .symbolSize(100)
                    }
                }

                if let selectedPrice {
                    RuleMark(
                        x: .value("Time", selectedPrice.timeSecond)
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
                           isVeryCloseToTrade(date: selectedPrice.timeSecond, trade: selectedTrade)
                        {
                            TooltipView(trade: selectedTrade)
                        } else {
                            PriceTooltipView(price: selectedPrice)
                        }
                    }
                }
            }
            .chartXSelection(value: $rawSelectedDate)
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.hour().minute().second())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel()
                }
            }
            .chartXScale(domain: visibleDateRange ?? Date()...Date()) // Default to current date
            .frame(height: 300)
        }
    }
}

// MARK: - Zoom and Pan Extensions

extension PriceChartView {
    func panChart(by deltaX: CGFloat) {
        guard let currentRange = visibleDateRange else { return }

        let currentSpan = currentRange.upperBound.timeIntervalSince(currentRange.lowerBound)
        // Convert pixel delta to time delta (negative because dragging right should move view left)
        let timeDelta = -Double(deltaX) * (currentSpan / 300) // Assuming chart width ~300

        let newStart = currentRange.lowerBound.addingTimeInterval(timeDelta)
        let newEnd = currentRange.upperBound.addingTimeInterval(timeDelta)

        visibleDateRange = newStart...newEnd
    }

    func setInitialDateRange() {
        guard !initialZoomSet, !trades.isEmpty else { return }

        // Find first and last trade times
        if let firstTradeTime = trades.map({ $0.confirmTime }).min(),
           let lastTradeTime = trades.map({ $0.confirmTime }).max()
        {
            // Add some padding (20% on each side)
            let timeSpan = lastTradeTime.timeIntervalSince(firstTradeTime)
            let padding = timeSpan * 0.2

            let startDate = firstTradeTime.addingTimeInterval(-padding)
            let endDate = lastTradeTime.addingTimeInterval(padding)

            visibleDateRange = startDate...endDate
            initialZoomSet = true
        } else if !priceData.isEmpty {
            // Fallback to price data if no trades
            if let firstTime = priceData.map({ $0.timeSecond }).min(),
               let lastTime = priceData.map({ $0.timeSecond }).max()
            {
                visibleDateRange = firstTime...lastTime
                initialZoomSet = true
            }
        }
    }

    func resetZoom() {
        initialZoomSet = false
        setInitialDateRange()
    }

    func zoomIn() {
        guard let currentRange = visibleDateRange else { return }

        let currentSpan = currentRange.upperBound.timeIntervalSince(currentRange.lowerBound)
        let newSpan = currentSpan * 0.8 // Zoom in by 20%

        let midPoint = currentRange.lowerBound.addingTimeInterval(currentSpan / 2)
        let newStart = midPoint.addingTimeInterval(-newSpan / 2)
        let newEnd = midPoint.addingTimeInterval(newSpan / 2)

        visibleDateRange = newStart...newEnd
    }

    func zoomOut() {
        guard let currentRange = visibleDateRange else { return }

        let currentSpan = currentRange.upperBound.timeIntervalSince(currentRange.lowerBound)
        let newSpan = currentSpan * 1.2 // Zoom out by 20%

        let midPoint = currentRange.lowerBound.addingTimeInterval(currentSpan / 2)
        let newStart = midPoint.addingTimeInterval(-newSpan / 2)
        let newEnd = midPoint.addingTimeInterval(newSpan / 2)

        visibleDateRange = newStart...newEnd
    }

    func zoomChart(by factor: CGFloat) {
        guard let currentRange = visibleDateRange else { return }

        let currentSpan = currentRange.upperBound.timeIntervalSince(currentRange.lowerBound)
        let newSpan = currentSpan / Double(factor)

        let midPoint = currentRange.lowerBound.addingTimeInterval(currentSpan / 2)
        let newStart = midPoint.addingTimeInterval(-newSpan / 2)
        let newEnd = midPoint.addingTimeInterval(newSpan / 2)

        visibleDateRange = newStart...newEnd
    }
}

// MARK: - Data Helper Extensions

extension PriceChartView {
    func calculateTradePrice(_ trade: PositionTradeData) -> Double {
        return Double(trade.actualQuoteTokenAmount) / Double(max(1, trade.actualBaseTokenAmount))
    }

    func findClosestPriceData(to date: Date) -> PriceData? {
        guard !priceData.isEmpty else { return nil }

        return priceData.min(by: {
            abs($0.timeSecond.timeIntervalSince(date)) < abs($1.timeSecond.timeIntervalSince(date))
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

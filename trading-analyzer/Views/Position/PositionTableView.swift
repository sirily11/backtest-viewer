//
//  PositionTableView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//
import SwiftUI

struct PositionTableView: View {
    let positions: [PositionData]
    let positionTradingFile: URL
    let postgresService: PostgresService

    @State private var sortOrder = [KeyPathComparator(\PositionData.pnlRatio, order: .reverse)]
    @State private var selection: PositionData.ID? = nil
    @State private var selectedPosition: PositionData? = nil
    @State private var showingPositionDetail = false

    @State private var positionTrades: [PositionTradeData] = []
    @State private var priceData: [PriceData] = []
    @State private var isLoadingTrades = false

    @Environment(AlertManager.self) var alert
    @Environment(\.openWindow) var openWindow

    private var sortedPositions: [PositionData] {
        return positions.sorted(using: sortOrder)
    }

    var body: some View {
        Table(sortedPositions, selection: $selection, sortOrder: $sortOrder) {
            marketIdColumn
            pnlRatioColumn
            pnlColumn
            costColumn
            maxProfitRatioColumn
            maxProfitColumn
            maxLossRatioColumn
            maxLossColumn
            createdColumn
            updatedColumn
        }
        .contextMenu(forSelectionType: UUID.self) { items in
            if let selectedID = selection, items.contains(selectedID) {
                Button("View Details") {
                    if let position = positions.first(where: { $0.id == selectedID }) {
                        Task {
                            selectedPosition = position
                            await loadPositionTrades(for: position)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingPositionDetail) {
            Group {
                PositionLoadingView(
                    position: selectedPosition,
                    trades: positionTrades,
                    priceData: priceData
                )
                .frame(minWidth: 600, minHeight: 600)
            }
        }
    }

    private func loadPositionTrades(for position: PositionData) async {
        withAnimation {
            isLoadingTrades = true
            showingPositionDetail = true
        }

        do {
            // Load trades for this position
            let allTrades = try await CSVParserService.parsePositionTradeData(
                from: positionTradingFile)
            positionTrades = allTrades.filter { $0.marketId == position.marketId }

            // Load price data if we have a PostgreSQL connection
            if postgresService.isConnected {
                // Calculate date range for price data
                // Use 1 day before first trade to 1 day after last trade
                if let firstTradeDate = positionTrades.map({ $0.confirmTime }).min(),
                   let lastTradeDate = positionTrades.map({ $0.confirmTime }).max()
                {
                    let startDate =
                        Calendar.current.date(byAdding: .day, value: -1, to: firstTradeDate)
                            ?? firstTradeDate
                    let endDate =
                        Calendar.current.date(byAdding: .day, value: 1, to: lastTradeDate)
                            ?? lastTradeDate

                    priceData = try await postgresService.fetchPriceData(
                        forMarketId: position.marketId,
                        startDate: startDate,
                        endDate: endDate
                    )
                }
            } else {
                openWindow(id: "settings")
                return
            }

        } catch {
            alert.showAlert(message: "Error loading position trades: \(error.localizedDescription)")
        }
        isLoadingTrades = false
    }
}

extension PositionTableView {
    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var marketIdColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Market ID", value: \.marketId) { position in
            Text(position.marketId)
                .font(.system(.body, design: .monospaced))
                .lineLimit(1)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var pnlRatioColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("PnL Ratio", value: \.pnlRatio) { position in
            Text("\(Double(position.pnlRatio) / 100.0)%")
                .foregroundStyle(position.pnlRatio >= 0 ? .green : .red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var pnlColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("PnL", value: \.pnl) { position in
            Text(position.pnl.lamportsToSol().formattedSol())
                .foregroundStyle(position.pnl >= 0 ? .green : .red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var costColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Cost", value: \.cost) { position in
            Text(position.cost.lamportsToSol().formattedSol())
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxProfitRatioColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Profit Ratio", value: \.maxProfitRatio) { position in
            Text("\(Double(position.maxProfitRatio) / 100.0)%")
                .foregroundStyle(.green)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxProfitColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Profit", value: \.maxProfit) { position in
            Text(position.maxProfit.lamportsToSol().formattedSol())
                .foregroundStyle(.green)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxLossRatioColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Loss Ratio", value: \.maxLossRatio) { position in
            Text("\(Double(position.maxLossRatio) / 100.0)%")
                .foregroundStyle(.red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxLossColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Loss", value: \.maxLoss) { position in
            Text(position.maxLoss.lamportsToSol().formattedSol())
                .foregroundStyle(.red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var createdColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Created", value: \.createTime) { position in
            Text(position.createTime, format: .dateTime)
                .font(.caption)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var updatedColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Updated", value: \.updateTime) { position in
            Text(position.updateTime, format: .dateTime)
                .font(.caption)
        }
    }
}

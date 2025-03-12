//
//  PositionTableView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//
import SwiftUI

struct PositionTableView: View {
    let positions: [PositionData]
    @State private var sortOrder = [KeyPathComparator(\PositionData.pnlRatio, order: .reverse)]
    @State private var selection: PositionData.ID? = nil

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
        }.contextMenu(forSelectionType: UUID.self) { items in
            if let selectedID = selection, items.contains(selectedID) {
                Button("View Details") {
                    // Action for the selected item
                    print("Selected: \(selectedID)")
                }
            }
        }
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
            Text("\(position.pnlRatio)%")
                .foregroundStyle(position.pnlRatio >= 0 ? .green : .red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var pnlColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("PnL", value: \.pnl) { position in
            Text("\(position.pnl)")
                .foregroundStyle(position.pnl >= 0 ? .green : .red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var costColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Cost", value: \.cost) { position in
            Text("\(position.cost)")
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxProfitRatioColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>>
    {
        TableColumn("Max Profit Ratio", value: \.maxProfitRatio) { position in
            Text("\(position.maxProfitRatio)%")
                .foregroundStyle(.green)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxProfitColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Profit", value: \.maxProfit) { position in
            Text("\(position.maxProfit)")
                .foregroundStyle(.green)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxLossRatioColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Loss Ratio", value: \.maxLossRatio) { position in
            Text("\(position.maxLossRatio)%")
                .foregroundStyle(.red)
        }
    }

    @TableColumnBuilder<PositionData, KeyPathComparator<PositionData>>
    var maxLossColumn: some TableColumnContent<PositionData, KeyPathComparator<PositionData>> {
        TableColumn("Max Loss", value: \.maxLoss) { position in
            Text("\(position.maxLoss)")
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

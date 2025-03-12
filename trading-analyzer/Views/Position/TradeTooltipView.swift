//
//  TooltipView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import SwiftUI

struct TooltipView: View {
    let trade: PositionTradeData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(trade.isBuy ? "Buy" : "Sell")
                    .font(.headline)
                    .foregroundStyle(trade.isBuy ? .green : .red)

                Spacer()

                Text(trade.confirmTime, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            Text("Action: \(trade.actionSummary)")
                .font(.caption)

            Text("Reason: \(trade.actionReason)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            HStack {
                Text("Price: \(trade.formattedPrice)")
                    .font(.caption)

                Spacer()

                Text("Amount: \(trade.formattedBaseAmount)")
                    .font(.caption)
            }

            if !trade.isBuy {
                HStack {
                    Text("PnL: \(trade.formattedPnl)")
                        .font(.caption)
                        .foregroundStyle(trade.actualPnl > 0 ? .green : .red)

                    Spacer()

                    Text("Ratio: \(trade.formattedPnlRatio)")
                        .font(.caption)
                        .foregroundStyle(trade.actualPnlRatio > 0 ? .green : .red)
                }
            }
        }
        .padding(8)
        .background(Color.primary.colorInvert())
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .frame(width: 250)
    }
}

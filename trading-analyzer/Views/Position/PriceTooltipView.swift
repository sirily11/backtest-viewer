//
//  PriceTooltipView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import SwiftUI

struct PriceTooltipView: View {
    let price: PriceData

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Price")
                    .font(.headline)

                Spacer()

                Text(price.timeSecond, format: .dateTime.hour().minute().second())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack {
                Text("Avg: \(String(format: "%.9f SOL", price.avgPriceInSol))")
                    .font(.caption)
                    .foregroundStyle(.blue)
            }

            HStack {
                Text("Min: \(String(format: "%.9f SOL", price.minPriceInSol))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Max: \(String(format: "%.9f SOL", price.maxPriceInSol))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("Transactions: \(price.transactionCount)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background(Color.primary.colorInvert())
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
        .frame(width: 200)
    }
}

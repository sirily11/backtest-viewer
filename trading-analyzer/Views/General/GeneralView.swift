//
//  GeneralView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import SwiftUI

struct GeneralView: View {
    let file: URL
    @State var stats: TradeStats? = nil

    var body: some View {
        VStack {
            if let stats = stats {
                TradeStatsView(trade: stats)
            } else {
                ProgressView()
            }
        }.task {
            await loadStats()
        }
        .onChange(of: file) { _, _ in
            Task {
                await loadStats()
            }
        }
    }
}

extension GeneralView {
    func loadStats() async {
        // read file content from file
        do {
            let content = try String(contentsOf: file, encoding: .utf8)
            // parse the json content
            let decoder = JSONDecoder()
            let tradeStats = try decoder.decode(TradeStats.self, from: content.data(using: .utf8)!)
            stats = tradeStats
        } catch {
            print("Error: \(error)")
        }
    }
}

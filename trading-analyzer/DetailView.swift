//
//  DetailView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

// Import the views
import SwiftUI

struct DetailView: View {
    let folder: URL
    let positionFile: URL
    let positionTradingFile: URL
    let generalInfoFile: URL

    init(folder: URL) {
        self.folder = folder
        self.positionFile = folder.appendingPathComponent("task").appendingPathComponent(
            "positions.csv")
        self.positionTradingFile = folder.appendingPathComponent("task").appendingPathComponent(
            "position_trade_records.csv")
        self.generalInfoFile = folder.appendingPathComponent("task").appendingPathComponent(
            "final-statistic.json")
    }

    var body: some View {
        TabView {
            GeneralView(file: generalInfoFile)
                .tabItem {
                    Label("General", systemImage: "info.circle")
                }

            PositionView(datasetName: folder.lastPathComponent, positionFile: positionFile, positionTradingFile: positionTradingFile)
                .tabItem {
                    Label("Position", systemImage: "chart.bar.xaxis")
                }
        }
        .frame(minWidth: 400, minHeight: 300)
        .padding()
    }
}

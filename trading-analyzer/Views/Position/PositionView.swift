//
//  PositionView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import SwiftUI

struct PositionView: View {
    let file: URL
    @State private var positions: [PositionData] = []
    @State private var isLoading = true
    @State private var error: Error?

    var body: some View {
        VStack {
            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding()
                    Button("Retry") {
                        Task {
                            await loadPositions()
                        }
                    }
                    .buttonStyle(.bordered)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if positions.isEmpty {
                VStack {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                    Text("No position data available")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                PositionTableView(positions: positions)
            }
        }
        .task {
            await loadPositions()
        }
        .onChange(of: file) { _, _ in
            Task {
                await loadPositions()
            }
        }
    }

    private func loadPositions() async {
        isLoading = true
        error = nil

        do {
            positions = try await CSVParserService.parsePositionData(from: file)
        } catch {
            self.error = error
            print("Error loading positions: \(error)")
        }

        isLoading = false
    }
}

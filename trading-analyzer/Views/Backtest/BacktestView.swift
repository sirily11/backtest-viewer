//
//  BacktestView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/17/25.
//

import Shimmer
import SwiftUI

struct BacktestView: View {
    @Environment(CommandService.self) var commandService
    @Environment(AlertManager.self) var alertManager

    @AppStorage("data-folder") private var dataFolder = ""
    @AppStorage("result-folder") private var resultFolder = ""
    @AppStorage("executable") private var executable = ""
    @AppStorage("make-file") private var makeFile = ""
    @AppStorage("plugin-folder") private var pluginFolder = ""
    @AppStorage("task-folder") private var taskFolder = ""
    @AppStorage("go-path") private var goPath = ""

    var body: some View {
        VStack {
            CommandView(
                title: "Generate accelerated data",
                description: "Generate accelerated data for the selected dataset",
                status: commandService.speedupStatus,
                run: {
                    runGenerateAcceleratedData()
                },
                cancel: {
                    commandService.cancelSpeedupDataGeneration()
                }
            )
            Divider()
            CommandView(
                title: "Run backtest",
                description: "Run backtest on the selected dataset",
                status: commandService.runBacktestStatus,
                run: {
                    runRunBacktest()
                },
                cancel: {
                    commandService.cancelBacktest()
                }
            )
        }
        .padding()
    }

    func runGenerateAcceleratedData() {
        if let executable = URL(string: executable),
            let dataFolder = URL(string: dataFolder)
        {
            Task {
                do {
                    try await commandService.runGenerateSpeedupHelperDataCommand(
                        executablePath: executable, dataFilePath: dataFolder
                    )
                } catch {
                    print(error)
                    alertManager.showAlert(message: error.localizedDescription)
                }
            }
        }
    }

    func runRunBacktest() {
        Task {
            do {
                if let makeFilePath = URL(string: makeFile),
                    let goBinaryPath = URL(string: goPath)
                {
                    try await commandService.runMakeCommand(
                        makeFilePath: makeFilePath, goBinaryPath: goBinaryPath
                    )
                }

                if let resultFilePath = URL(string: resultFolder),
                    let dataFilePath = URL(string: dataFolder),
                    let taskFilePath = URL(string: taskFolder),
                    let strategyFilePath = URL(string: pluginFolder),
                    let executableFilePath = URL(string: executable)
                {
                    try await commandService.runBacktestCommand(
                        resultFilePath: resultFilePath, dataFilePath: dataFilePath,
                        taskFilePath: taskFilePath, strategyFilePath: strategyFilePath,
                        executableFilePath: executableFilePath
                    )
                }
            } catch {
                print(error)
                alertManager.showAlert(message: error.localizedDescription)
            }
        }
    }
}

struct CommandView: View {
    let title: String
    let description: String
    let status: CommandStatus
    let run: () -> Void
    let cancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                    Text(description)
                        .font(.caption)
                }
                Spacer()

                if status.isRunning {
                    Button {
                        cancel()
                    } label: {
                        Label("Cancel", systemImage: "stop.fill")
                            .foregroundColor(.red)
                    }
                } else {
                    Button {
                        run()
                    } label: {
                        Label("Run", systemImage: "play.fill")
                    }
                }
            }

            statusView
                .modifier(StatusViewModifier(status: status))
        }
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .notRunning:
            EmptyView()

        case .running(let output):
            if let output = output, !output.isEmpty {
                Text(output.removeANSIColorCodes().trim())
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                Text("Running...")
                    .shimmering(
                        gradient: .init(colors: [
                            .gray.opacity(0.7), .black.opacity(1), .gray.opacity(0.7),
                        ])
                    )
                    .font(.caption)
                    .foregroundColor(.primary)
            }

        case .success:
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Task completed successfully")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .canceled:
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.orange)
                Text("Task was canceled")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

        case .failure(let error):
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(
                        error.localizedDescription.components(separatedBy: ":").first
                            ?? error.localizedDescription
                    )
                    .font(.caption)
                    .foregroundColor(.red)

                    Spacer()

                    Button {
                        // This would show a popup with detailed error information
                        print("Error details: \(error)")
                    } label: {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
    }
}

extension CommandView {
    struct StatusViewModifier: ViewModifier {
        let status: CommandStatus

        func body(content: Content) -> some View {
            content
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .opacity(status == .notRunning ? 0 : 1)
        }
    }
}

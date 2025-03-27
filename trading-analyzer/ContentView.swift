//
//  ContentView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/12/25.
//

import SwiftUI

struct ContentView: View {
    @State private var isOpenFolder = false
    @State private var folders = [URL]()
    @State private var showRunPopup = false
    @State private var resultFolderWatcher: FolderMonitor? = nil

    @AppStorage("result-folder") var resultFolder: String = ""
    @AppStorage("data-folder") var dataFolder: String = ""
    @AppStorage("task-folder") private var taskFolder = ""
    @State private var navigation: Navigation? = nil
    @AppStorage("has-initialized") var hasInitialized = false
    @Environment(CommandService.self) var commandService
    @Environment(AlertManager.self) var alertManager

    var body: some View {
        Group {
            if folders.count > 0 {
                NavigationSplitView(
                    sidebar: {
                        List(selection: $navigation) {
                            Section {
                                if let resultFolder = URL(string: resultFolder) {
                                    let summaryFileURL = resultFolder.appending(
                                        path: "summary-results.json")
                                    if FileManager.default.fileExists(atPath: summaryFileURL.path) {
                                        NavigationLink(value: Navigation.summary(summaryFileURL)) {
                                            Label("Summary", systemImage: "list.bullet.rectangle")
                                        }
                                    }
                                }
                            }
                            Section("Individual results") {
                                ForEach(folders, id: \.self) { folder in
                                    NavigationLink(value: Navigation.individualResult(folder)) {
                                        Text(folder.lastPathComponent)
                                    }
                                }
                            }
                        }

                    },
                    detail: {
                        switch navigation {
                        case .individualResult(let folder):
                            IndividualResultView(folder: folder)
                                .navigationTitle("Trading Analyzer")

                        case .summary(let url):
                            SummaryView(url: url)

                        case nil:
                            EmptyView()
                        }
                    })
            } else {
                buildEmptyView()
            }
        }
        .onDisappear {
            resultFolderWatcher?.stopMonitoring()
        }
        .alert(
            alertManager.alertTitle,
            isPresented: alertManager.isAlertPresentedBinding,
            actions: {
                Button("OK", role: .cancel) {
                    alertManager.hideAlert()
                }
            },
            message: {
                Text(
                    alertManager.alertMessage.count > 1000
                        ? alertManager.alertMessage.prefix(997) + "..." : alertManager.alertMessage)
            }
        )
        .onChange(of: resultFolder) { _, _ in
            print("Reload folders")
            if let url = URL(string: resultFolder) {
                readFoldersInDirectory(directory: url)
                Task {
                    await watchFolder(folder: url)
                }
            }
        }
        .task {
            print("Working folder: \(resultFolder)")
            if let url = URL(string: resultFolder) {
                readFoldersInDirectory(directory: url)
                await watchFolder(folder: url)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                OpenFinderButton(folderOptions: [
                    .init(
                        url: URL(string: resultFolder) ?? URL(fileURLWithPath: ""),
                        title: "Open Result Folder"),
                    .init(
                        url: URL(string: taskFolder) ?? URL(fileURLWithPath: ""),
                        title: "Open Task Folder"),
                    .init(
                        url: URL(string: dataFolder) ?? URL(fileURLWithPath: ""),
                        title: "Open Data Folder"),
                ])

                Button {
                    showRunPopup = true
                } label: {
                    if commandService.speedupStatus.isRunning
                        || commandService.runBacktestStatus.isRunning
                    {
                        ProgressView()
                            .frame(width: 20, height: 20)
                    } else {
                        Label("Run backtest", systemImage: "play.fill")
                    }
                }
                .popover(isPresented: $showRunPopup) {
                    BacktestView()
                }
                .help("Run back test")
            }
        }
    }

    @ViewBuilder
    func buildEmptyView() -> some View {
        VStack {
            Text("No results found in the folder")
            Button("Check settings") {
                hasInitialized = false
            }
        }
        .padding()
    }
}

extension ContentView {
    func readFoldersInDirectory(directory: URL) {
        // get list of the folders in the directory
        let fileManager = FileManager.default
        do {
            let files = try fileManager.contentsOfDirectory(atPath: directory.path)
            let folders = files.filter {
                var isDir: ObjCBool = false
                let filePath = directory.appendingPathComponent($0)
                fileManager.fileExists(atPath: filePath.path, isDirectory: &isDir)
                return isDir.boolValue
            }.map {
                directory.appendingPathComponent($0)
            }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            self.folders = folders
        } catch {
            print("Error: \(error)")
        }
    }

    func watchFolder(folder: URL) async {
        resultFolderWatcher?.stopMonitoring()
        resultFolderWatcher = FolderMonitor(url: folder)
        for await _ in resultFolderWatcher!.startMonitoring() {
            readFoldersInDirectory(directory: folder)
        }
    }
}

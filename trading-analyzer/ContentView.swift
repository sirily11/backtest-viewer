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

    @AppStorage("result-folder") var resultFolder: String = ""
    @State private var selectedFolder: URL? = nil
    @State private var hasLoaded = false
    @AppStorage("has-initialized") var hasInitialized = false
    @Environment(CommandService.self) var commandService
    @Environment(AlertManager.self) var alertManager

    var body: some View {
        Group {
            if folders.count > 0 {
                NavigationSplitView(sidebar: {
                    HStack {
                        Text("Individual results")
                            .foregroundStyle(.gray)
                        Spacer()
                    }
                    .padding(.horizontal)
                    List(folders, id: \.self, selection: $selectedFolder) { folder in
                        NavigationLink(value: folder) {
                            Text(folder.lastPathComponent)
                        }
                    }
                    .frame(minWidth: 200)
                }, detail: {
                    if let folder = selectedFolder {
                        DetailView(folder: folder)
                            .navigationTitle("Trading Analyzer")
                    }
                })
            } else {
                if !hasLoaded {
                    ProgressView()
                } else {
                    buildEmptyView()
                }
            }
        }
        .alert(alertManager.alertTitle,
               isPresented: alertManager.isAlertPresentedBinding,
               actions: {
                   Button("OK", role: .cancel) {
                       alertManager.hideAlert()
                   }
               }, message: {
                   Text(alertManager.alertMessage.count > 1000 ?
                       alertManager.alertMessage.prefix(997) + "..." :
                       alertManager.alertMessage)
               })
        .onChange(of: resultFolder) { _, _ in
            print("Reload folders")
            if let url = URL(string: resultFolder) {
                readFoldersInDirectory(directory: url)
            }
        }
        .onChange(of: commandService.runBacktestStatus) { oldValue, newValue in
            if oldValue.isRunning && !newValue.isRunning {
                print("Strategy finished, reload folders")
                if let url = URL(string: resultFolder) {
                    readFoldersInDirectory(directory: url)
                }
            }
        }
        .task {
            print("Working folder: \(resultFolder)")
            if let url = URL(string: resultFolder) {
                readFoldersInDirectory(directory: url)
            }
            withAnimation {
                hasLoaded = true
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showRunPopup = true
                } label: {
                    if commandService.speedupStatus.isRunning || commandService.runBacktestStatus.isRunning {
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
        HStack {
            Text("You are not open any back test results folder yet.")

            Button("Pick a folder") {
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
            self.folders = folders
        } catch {
            print("Error: \(error)")
        }
    }
}

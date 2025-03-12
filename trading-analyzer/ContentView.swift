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
    @AppStorage("working-folder") var workingFolder: String = ""
    @State private var selectedFolder: URL? = nil
    @State private var hasLoaded = false

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
                   Text(alertManager.alertMessage)
               })
        .onChange(of: workingFolder) { _, _ in
            print("Reload folders")
            if let url = URL(string: workingFolder) {
                readFoldersInDirectory(directory: url)
            }
        }
        .task {
            print("Working folder: \(workingFolder)")
            if let url = URL(string: workingFolder) {
                readFoldersInDirectory(directory: url)
            }
            withAnimation {
                hasLoaded = true
            }
        }
    }

    @ViewBuilder
    func buildEmptyView() -> some View {
        HStack {
            Text("You are not open any back test results folder yet.")

            Button("Pick a folder") {
                isOpenFolder.toggle()
            }
            .fileImporter(isPresented: $isOpenFolder, allowedContentTypes: [.directory]) { result in
                switch result {
                case .success(let dictionary):
                    self.workingFolder = dictionary.absoluteString
                case .failure(let error):
                    print(error)
                }
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

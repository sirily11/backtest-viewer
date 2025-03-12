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
    @State private var selectedFolder: URL? = nil

    var body: some View {
        if folders.count > 0 {
            NavigationSplitView(sidebar: {
                HStack {
                    Text("Results")
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
                if let selectedFolder = selectedFolder {
                    DetailView(folder: selectedFolder)
                        .navigationTitle("Trading Analyzer")
                }
            })
        } else {
            buildEmptyView()
        }
    }

    @ViewBuilder
    func buildEmptyView() -> some View {
        HStack {
            Text("Pick a folder")
            Button("Pick a folder") {
                isOpenFolder.toggle()
            }
            .fileImporter(isPresented: $isOpenFolder, allowedContentTypes: [.directory]) { result in
                switch result {
                case .success(let dictionary):
                    let gotAccess = dictionary.startAccessingSecurityScopedResource()
                    if !gotAccess {
                        return
                    }
                    readFoldersInDirectory(directory: dictionary)
                    dictionary.stopAccessingSecurityScopedResource()
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

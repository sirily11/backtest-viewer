//
//  GeneralSettingsView.swift
//  trading-analyzer
//
//  Created by Qiwei Li on 3/17/25.
//

import SwiftUI
import UniformTypeIdentifiers

private enum FilePickerType: CaseIterable {
    case dataFolder
    case resultFolder
    case pluginFolder
    case taskFolder
    case executable
    case makeFile

    var title: String {
        switch self {
        case .dataFolder:
            return "Data Folder"
        case .resultFolder:
            return "Result Folder"
        case .executable:
            return "Executable"
        case .pluginFolder:
            return "Plugin Folder"
        case .taskFolder:
            return "Task Folder"
        case .makeFile:
            return "Makefile"
        }
    }

    var allowedContentTypes: [UTType] {
        switch self {
        case .dataFolder, .resultFolder, .pluginFolder, .taskFolder:
            return [.directory]
        case .executable:
            return [.executable]
        case .makeFile:
            return [.makefile]
        }
    }

    func isCorrectFolder(_ url: URL) -> Bool {
        switch self {
        case .resultFolder:
            // check summary-results.json in the folder
            let fileManager = FileManager.default
            let summaryResultFile = url.appendingPathComponent("summary-results.json")
            return fileManager.fileExists(atPath: summaryResultFile.path)
        case .dataFolder:
            // check if any parquet file in the folder
            let fileManager = FileManager.default
            let contents = try? fileManager.contentsOfDirectory(
                at: url, includingPropertiesForKeys: nil
            )
            return contents?.contains { $0.pathExtension == "parquet" } ?? false
        default:
            return true
        }
    }
}

typealias OnAllSet = () -> Void

struct GeneralSettingsView: View {
    @AppStorage("data-folder") private var dataFolder = ""
    @AppStorage("result-folder") private var resultFolder = ""
    @AppStorage("executable") private var executable = ""
    @AppStorage("make-file") private var makeFile = ""
    @AppStorage("plugin-folder") private var pluginFolder = ""
    @AppStorage("task-folder") private var taskFolder = ""
    @AppStorage("go-path") private var goPath = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(CommandService.self) var commandService
    @State var alertManager = AlertManager()

    @State private var showFilePicker = false
    @State private var filePickerType: FilePickerType? = nil

    let onAllSet: OnAllSet?

    init() {
        onAllSet = nil
    }

    init(onAllSet: @escaping OnAllSet) {
        self.onAllSet = onAllSet
    }

    var body: some View {
        VStack(alignment: .leading) {
            Section {
                Text("Go Executable Path")
                TextField("Go Path", text: $goPath)
                Divider()
                ForEach(FilePickerType.allCases, id: \.self) { picker in
                    GeneralSettingsRow(
                        value: {
                            switch picker {
                            case .dataFolder:
                                return dataFolder
                            case .resultFolder:
                                return resultFolder
                            case .executable:
                                return executable
                            case .makeFile:
                                return makeFile
                            case .pluginFolder:
                                return pluginFolder
                            case .taskFolder:
                                return taskFolder
                            }
                        }, targetFilePickerType: picker, filePickerType: $filePickerType,
                        showFilePicker: $showFilePicker
                    )

                    if picker != FilePickerType.allCases.last {
                        Divider()
                    }
                }
            }
            Spacer()
        }
        .task {
            if !goPath.isEmpty {
                return
            }
            // get go path from system
            do {
                let goPath = try commandService.getGoPath()
                self.goPath = goPath
            } catch {
                print(error)
                alertManager.showAlert(message: error.localizedDescription)
            }
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
                Text(alertManager.alertMessage)
            }
        )
        .listStyle(.plain)
        .insetGroupedStyle(header: "Path")
        .onAppear {
            if checkAllSet() {
                onAllSet?()
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: filePickerType?.allowedContentTypes ?? []
        ) { result in
            switch result {
            case .success(let dictionary):
                // check if the folder is correct
                if let filePickerType = filePickerType, !filePickerType.isCorrectFolder(dictionary) {
                    alertManager.showAlert(
                        message: "The selected folder is not correct for \(filePickerType.title)")
                    return
                }
                switch filePickerType {
                case .dataFolder:
                    dataFolder = dictionary.absoluteString
                case .resultFolder:
                    resultFolder = dictionary.absoluteString
                case .executable:
                    executable = dictionary.absoluteString
                case .makeFile:
                    makeFile = dictionary.absoluteString
                case .pluginFolder:
                    pluginFolder = dictionary.absoluteString
                case .taskFolder:
                    taskFolder = dictionary.absoluteString
                case .none:
                    break
                }
                if checkAllSet() {
                    onAllSet?()
                }
            case .failure(let error):
                alertManager.showAlert(message: error.localizedDescription)
            }
        }
    }

    func checkAllSet() -> Bool {
        if dataFolder.isEmpty || resultFolder.isEmpty || executable.isEmpty || makeFile.isEmpty
            || pluginFolder.isEmpty || taskFolder.isEmpty || goPath.isEmpty
        {
            return false
        }

        return true
    }
}

private struct GeneralSettingsRow: View {
    let value: () -> String
    let targetFilePickerType: FilePickerType

    @Binding var filePickerType: FilePickerType?
    @Binding var showFilePicker: Bool

    var body: some View {
        VStack(alignment: .leading) {
            Text("Select \(targetFilePickerType.title)")
            if let url = URL(string: value()) {
                Text(url.path)
                    .foregroundColor(.secondary)
            } else {
                Text("Not selected")
                    .foregroundColor(.secondary)
            }

            HStack {
                Spacer()
                Button("Change folder") {
                    filePickerType = targetFilePickerType
                    showFilePicker = true
                }
            }
        }
    }
}

extension View {
    func insetGroupedStyle(header: String) -> some View {
        return GroupBox(
            label: Text(header.uppercased()).font(.headline).padding(.top).padding(.bottom, 6)
        ) {
            VStack {
                self.padding(.vertical, 3)
            }.padding(.horizontal).padding(.vertical)
        }
    }
}

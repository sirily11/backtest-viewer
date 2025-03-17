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
        case .makeFile:
            return "Makefile"
        }
    }

    var allowedContentTypes: [UTType] {
        switch self {
        case .dataFolder, .resultFolder:
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
            let contents = try? fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
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

    @Environment(\.dismiss) private var dismiss
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
                ForEach(FilePickerType.allCases, id: \.self) { picker in
                    GeneralSettingsRow(value: {
                        switch picker {
                        case .dataFolder:
                            return dataFolder
                        case .resultFolder:
                            return resultFolder
                        case .executable:
                            return executable
                        case .makeFile:
                            return makeFile
                        }
                    }, targetFilePickerType: picker, filePickerType: $filePickerType, showFilePicker: $showFilePicker)

                    Divider()
                }
            }
            Spacer()
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
        .listStyle(.plain)
        .insetGroupedStyle(header: "Path")
        .onAppear {
            if checkAllSet() {
                onAllSet?()
            }
        }
        .fileImporter(isPresented: $showFilePicker, allowedContentTypes: filePickerType?.allowedContentTypes ?? []) { result in
            switch result {
            case .success(let dictionary):
                // check if the folder is correct
                if let filePickerType = filePickerType, !filePickerType.isCorrectFolder(dictionary) {
                    alertManager.showAlert(message: "The selected folder is not correct for \(filePickerType.title)")
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
        if dataFolder.isEmpty || resultFolder.isEmpty || executable.isEmpty || makeFile.isEmpty {
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
        return GroupBox(label: Text(header.uppercased()).font(.headline).padding(.top).padding(.bottom, 6)) {
            VStack {
                self.padding(.vertical, 3)
            }.padding(.horizontal).padding(.vertical)
        }
    }
}

import SwiftUI

struct SettingsView: View {
    @AppStorage("data-folder") private var dataFolder = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(DuckDBService.self) private var model
    @State var showingFolderPicker = false
    @Environment(AlertManager.self) private var alertManager

    var body: some View {
        TabView {
            Form {
                if let url = URL(string: dataFolder) {
                    HStack {
                        Text("Current data folder:")
                        Spacer()
                        Text(url.path)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("No folder selected")
                }
                HStack {
                    Spacer()
                    Button("Change folder") {
                        showingFolderPicker = true
                    }
                    .fileImporter(isPresented: $showingFolderPicker, allowedContentTypes: [.directory]) { result in
                        switch result {
                        case .success(let dictionary):
                            dataFolder = dictionary.absoluteString
                        case .failure(let error):
                            alertManager.showAlert(message: error.localizedDescription)
                        }
                    }
                }
            }
            .tabItem {
                Label("DuckDB Settings", systemImage: "info.circle")
            }
            .padding()
            .navigationTitle("Settings")
        }
        .frame(maxWidth: 400, maxHeight: 300)
    }
}

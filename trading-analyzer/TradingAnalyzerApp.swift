import SwiftUI
import UniformTypeIdentifiers

@main
struct TradingAnalyzerApp: App {
    @State private var duckDBService = DuckDBService()
    @State private var alertManager = AlertManager()
    @Environment(\.openWindow) var open

    @AppStorage("postgres:host") private var host = "localhost"
    @AppStorage("postgres:port") private var port = 5432
    @AppStorage("postgres:username") private var username = ""
    @AppStorage("postgres:password") private var password = ""
    @AppStorage("postgres:database") private var database = ""
    @AppStorage("working-folder") var workingFolder: String = ""

    @State private var isOpenFolder = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(duckDBService)
                .environment(alertManager)
                .task {
                    // Connect to PostgreSQL if we have a connection string
                    do {
                        try duckDBService.initDatabase()
                    } catch {
                        alertManager.showAlert(message: error.localizedDescription)
                    }
                }
        }

        Window("Settings", id: "settings") {
            SettingsView()
                .environment(duckDBService)
                .environment(alertManager)
        }
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appSettings) {
                Button("Settings") {
                    // Open the settings window
                    open(id: "settings")
                }
            }

            CommandGroup(replacing: CommandGroupPlacement.newItem) {
                Button("Open new results folder") {
                    isOpenFolder = true
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
        }
        .defaultSize(width: 500, height: 400)
    }
}

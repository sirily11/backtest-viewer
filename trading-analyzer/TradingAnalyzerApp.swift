import Sparkle
import SwiftUI
import UniformTypeIdentifiers

var updaterController: SPUStandardUpdaterController?
let updaterDelegate = UpdaterDelegate()

@main
struct TradingAnalyzerApp: App {
    @State private var duckDBService = DuckDBService()
    @State private var alertManager = AlertManager()
    @State private var commandService = CommandService()

    @Environment(\.openWindow) var open
    @AppStorage("has-initialized") var hasInitialized = false
    @State var showWelcomeSheet = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, updaterDelegate: updaterDelegate, userDriverDelegate: nil)
        updaterController?.updater.updateCheckInterval = 80
        updaterController?.updater.automaticallyChecksForUpdates = true
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(duckDBService)
                .environment(alertManager)
                .environment(commandService)
                .task {
                    // Connect to PostgreSQL if we have a connection string
                    do {
                        try duckDBService.initDatabase()
                        if !hasInitialized {
                            showWelcomeSheet = true
                        }
                    } catch {
                        alertManager.showAlert(message: error.localizedDescription)
                    }
                }
                .sheet(isPresented: $showWelcomeSheet) {
                    WelcomeView()
                        .environment(alertManager)
                        .environment(commandService)
                }
        }

        Window("Settings", id: "settings") {
            SettingsView()
                .environment(alertManager)
                .environment(commandService)
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
                Button("Open folder") {
                    showWelcomeSheet = true
                }
            }

            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    updaterController?.checkForUpdates(nil)
                }
            }
        }
        .defaultSize(width: 500, height: 400)
    }
}

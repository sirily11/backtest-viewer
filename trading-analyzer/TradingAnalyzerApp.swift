import SwiftUI
import UniformTypeIdentifiers

@main
struct TradingAnalyzerApp: App {
    @State private var duckDBService = DuckDBService()
    @State private var alertManager = AlertManager()
    @Environment(\.openWindow) var open
    @AppStorage("has-initialized") var hasInitialized = false

    var showWelcomeSheet: Binding<Bool> {
        get {
            Binding<Bool>(
                get: { !hasInitialized },
                set: { isShowing in
                    hasInitialized = !isShowing
                }
            )
        }

        set {
            hasInitialized = !newValue.wrappedValue
        }
    }

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
                .sheet(isPresented: showWelcomeSheet) {
                    WelcomeView()
                        .environment(alertManager)
                }
        }

        Window("Settings", id: "settings") {
            SettingsView()
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
                Button("Open folder") {
                    hasInitialized = false
                }
            }
        }
        .defaultSize(width: 500, height: 400)
    }
}

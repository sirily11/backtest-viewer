import SwiftUI
import UniformTypeIdentifiers

@main
struct TradingAnalyzerApp: App {
    @State private var postgresService = PostgresService()
    @State private var alertManager = AlertManager()
    @Environment(\.openWindow) var open

    @AppStorage("postgres:host") private var host = "localhost"
    @AppStorage("postgres:port") private var port = 5432
    @AppStorage("postgres:username") private var username = ""
    @AppStorage("postgres:password") private var password = ""
    @AppStorage("postgres:database") private var database = ""

    init() {
        let service = PostgresService()
        _postgresService = State(initialValue: service)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(postgresService)
                .environment(alertManager)
                .task {
                    // Connect to PostgreSQL if we have a connection string
                    await postgresService.connect(host: host, port: port, username: username, password: password, database: database)
                }
        }

        Window("Settings", id: "settings") {
            SettingsView()
                .environment(postgresService)
        }
        .commands {
            CommandGroup(replacing: CommandGroupPlacement.appSettings) {
                Button("Postgres Connection") {
                    // Open the settings window
                    open(id: "settings")
                }
            }
        }
        .defaultSize(width: 500, height: 400)
    }
}

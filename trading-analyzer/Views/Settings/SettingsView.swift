import SwiftUI

struct SettingsView: View {
    @AppStorage("postgres:host") private var host = "localhost"
    @AppStorage("postgres:port") private var port = 5432
    @AppStorage("postgres:username") private var username = ""
    @AppStorage("postgres:password") private var password = ""
    @AppStorage("postgres:database") private var database = ""

    @Environment(\.dismiss) private var dismiss
    @Environment(PostgresService.self) private var model
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Database Connection")) {
                    TextField("Host", text: $host)
                    TextField("Port", value: $port, format: .number)

                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    TextField("Database", text: $database)

                    if let error = model.connectionError {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    HStack {
                        Text("Connection Status:")
                        Spacer()
                        if isSaving {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Text(
                                model.isConnected ? "Connected" : "Disconnected"
                            )
                            .foregroundStyle(model.isConnected ? .green : .red)
                        }
                    }
                }

                Section {
                    Button(action: {
                        Task {
                            isSaving = true
                            await model.connect(
                                host: host,
                                port: port,
                                username: username,
                                password: password,
                                database: database
                            )
                            isSaving = false
                        }
                    }) {
                        Text("Save Settings")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(isSaving)
                }
            }
            .padding()
            .navigationTitle("Settings")
        }
    }
}

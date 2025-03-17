import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State var showingFolderPicker = false
    @Environment(AlertManager.self) private var alertManager

    var body: some View {
        TabView {
            GeneralSettingsView()
                .padding()
                .tabItem {
                    Label("General Settings", systemImage: "info.circle")
                }
                .padding()
                .navigationTitle("Settings")
        }
        .frame(minWidth: 400, maxWidth: 600)
    }
}

import SwiftUI

struct SettingsView: View {
    @AppStorage("data-folder") private var dataFolder = ""
    @AppStorage("result-folder") private var resultFolder = ""
    @AppStorage("executable") private var executable = ""
    @AppStorage("make-file") private var makeFile = ""

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

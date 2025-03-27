import SwiftUI

/// A button that opens a menu containing options to open various folders in Finder
struct OpenFinderButton: View {
    /// A struct to hold the URL and title for each folder option
    struct FolderOption: Identifiable {
        let id = UUID()
        let url: URL
        let title: String
    }

    /// List of folder options to display in the menu
    let folderOptions: [FolderOption]

    var body: some View {
        Menu {
            ForEach(folderOptions) { option in
                Button {
                    NSWorkspace.shared.open(option.url)
                } label: {
                    Label(option.title, systemImage: "folder")
                }
            }
        } label: {
            Label("Open folder", systemImage: "square.and.arrow.up")
        }
        .menuStyle(.button)
    }
}

#Preview {
    OpenFinderButton(folderOptions: [
        .init(url: URL(fileURLWithPath: "/Users/test/result"), title: "Open Result Folder"),
        .init(url: URL(fileURLWithPath: "/Users/test/data"), title: "Open Data Folder"),
    ])
}

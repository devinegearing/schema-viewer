import SwiftUI

@main
struct SchemaViewerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        DocumentGroup(viewing: SchemaDocument.self) { config in
            SchemaWebView(source: config.document.source, fileURL: config.fileURL)
                .ignoresSafeArea()
        }
        .defaultSize(width: 1200, height: 800)
        .commands {
            CommandGroup(after: .appInfo) {
                Button("Check for Updates...") {
                    appDelegate.checkForUpdates()
                }
                .disabled(!appDelegate.canCheckForUpdates)
            }
        }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var updateController: UpdateController!

    var canCheckForUpdates: Bool {
        updateController?.canCheckForUpdates ?? false
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        updateController = UpdateController()
    }

    func checkForUpdates() {
        updateController.checkForUpdates()
    }
}

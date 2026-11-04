import AppKit
import SwiftUI

@main
enum Main {
    @MainActor
    static func main() {
        let arguments = CommandLine.arguments
        if arguments.contains("--status") {
            // Prints what Wakey detects and decides, without changing anything.
            _ = NSApplication.shared
            let model = AppModel(applyEffects: false)
            model.sampleNow()
            print(model.statusReport)
            return
        }
        if let index = arguments.firstIndex(of: "--snapshot"), index + 1 < arguments.count {
            Snapshot.run(directory: arguments[index + 1])
            return
        }
        WakeyApp.main()
    }
}

struct WakeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @ObservedObject private var model = AppModel.shared

    var body: some Scene {
        MenuBarExtra {
            MenuPanel()
                .environmentObject(model)
                .preferredColorScheme(model.colorScheme)
        } label: {
            Image(nsImage: MenuBarIcon.image(active: model.decision.isActive, lidMode: model.decision.lidMode))
        }
        .menuBarExtraStyle(.window)
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        AppModel.shared.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        AppModel.shared.shutdown()
    }
}

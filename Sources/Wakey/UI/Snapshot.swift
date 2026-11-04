import AppKit
import SwiftUI
import WakeyCore

/// `Wakey --snapshot <dir>` renders the menu panel and Settings window to PNG
/// files in every language and appearance, using this Mac's live state.
/// Nothing is changed on the system.
@MainActor
enum Snapshot {
    static func run(directory: String) {
        let app = NSApplication.shared
        app.setActivationPolicy(.prohibited)
        let folder = URL(fileURLWithPath: directory, isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let model = AppModel(applyEffects: false)
        model.sampleNow()

        for language in AppLanguage.allCases {
            model.language = language
            for dark in [false, true] {
                let suffix = "\(language.rawValue)-\(dark ? "dark" : "light")"
                render(
                    MenuPanel(showAdvanced: language == .english)
                        .environmentObject(model)
                        .background(Color(nsColor: .windowBackgroundColor)),
                    dark: dark,
                    to: folder.appendingPathComponent("menu-\(suffix).png")
                )
            }
        }

        let settingsShots: [(AppLanguage, Bool, SettingsTab, String)] = [
            (.english, false, .general, "settings-general-en-light"),
            (.korean, true, .general, "settings-general-ko-dark"),
            (.japanese, false, .detection, "settings-detection-ja-light"),
            (.english, true, .detection, "settings-detection-en-dark"),
            (.korean, false, .about, "settings-about-ko-light")
        ]
        for (language, dark, tab, name) in settingsShots {
            model.language = language
            render(
                SettingsView(initialTab: tab)
                    .environmentObject(model)
                    .background(Color(nsColor: .windowBackgroundColor)),
                dark: dark,
                to: folder.appendingPathComponent("\(name).png")
            )
        }
        print("Saved snapshots to \(folder.path)")
    }

    private static func render<V: View>(_ view: V, dark: Bool, to url: URL) {
        let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        NSApp.appearance = appearance
        let host = NSHostingView(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
        host.appearance = appearance
        let size = host.fittingSize
        host.frame = NSRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = appearance
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
    }
}

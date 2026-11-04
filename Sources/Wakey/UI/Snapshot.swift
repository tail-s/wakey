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
            var panels: [NSBitmapImageRep] = []
            for dark in [false, true] {
                let suffix = "\(language.rawValue)-\(dark ? "dark" : "light")"
                let panel = MenuPanel(showAdvanced: false)
                    .environmentObject(model)
                    .background(Color(nsColor: .windowBackgroundColor))
                write(bitmap(panel, dark: dark), to: folder.appendingPathComponent("menu-\(suffix).png"))
                // Rounded like the real menu, for the README.
                if let rounded = bitmap(
                    panel.clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous)),
                    dark: dark
                ) {
                    panels.append(rounded)
                }
            }
            if panels.count == 2 {
                write(sideBySide(panels[0], panels[1], gap: 64), to: folder.appendingPathComponent("readme-menu-\(language.rawValue).png"))
            }
        }

        model.language = .english
        write(
            bitmap(MenuPanel(showAdvanced: true).environmentObject(model).background(Color(nsColor: .windowBackgroundColor)), dark: false),
            to: folder.appendingPathComponent("menu-en-light-advanced.png")
        )

        let settingsShots: [(AppLanguage, Bool, SettingsTab, String)] = [
            (.english, false, .general, "settings-general-en-light"),
            (.korean, true, .general, "settings-general-ko-dark"),
            (.japanese, false, .detection, "settings-detection-ja-light"),
            (.english, true, .detection, "settings-detection-en-dark"),
            (.korean, false, .about, "settings-about-ko-light")
        ]
        for (language, dark, tab, name) in settingsShots {
            model.language = language
            write(
                bitmap(
                    SettingsView(initialTab: tab)
                        .environmentObject(model)
                        .background(Color(nsColor: .windowBackgroundColor)),
                    dark: dark
                ),
                to: folder.appendingPathComponent("\(name).png")
            )
        }
        print("Saved snapshots to \(folder.path)")
    }

    private static func bitmap<V: View>(_ view: V, dark: Bool) -> NSBitmapImageRep? {
        let appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        NSApp.appearance = appearance
        let host = NSHostingView(rootView: view.environment(\.colorScheme, dark ? .dark : .light))
        host.appearance = appearance
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.appearance = appearance
        window.backgroundColor = .clear
        window.isOpaque = false
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.4))
        guard let bitmap = host.bitmapImageRepForCachingDisplay(in: host.bounds) else { return nil }
        host.cacheDisplay(in: host.bounds, to: bitmap)
        return bitmap
    }

    private static func sideBySide(_ left: NSBitmapImageRep, _ right: NSBitmapImageRep, gap: Int) -> NSBitmapImageRep? {
        let width = left.pixelsWide + gap + right.pixelsWide
        let height = max(left.pixelsHigh, right.pixelsHigh)
        guard let canvas = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: width, pixelsHigh: height, bitsPerSample: 8, samplesPerPixel: 4,
            hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
        ), let context = NSGraphicsContext(bitmapImageRep: canvas) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context
        left.draw(in: NSRect(x: 0, y: height - left.pixelsHigh, width: left.pixelsWide, height: left.pixelsHigh))
        right.draw(in: NSRect(x: left.pixelsWide + gap, y: height - right.pixelsHigh, width: right.pixelsWide, height: right.pixelsHigh))
        NSGraphicsContext.restoreGraphicsState()
        return canvas
    }

    private static func write(_ bitmap: NSBitmapImageRep?, to url: URL) {
        try? bitmap?.representation(using: .png, properties: [:])?.write(to: url)
    }
}

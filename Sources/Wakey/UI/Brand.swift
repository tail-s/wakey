import AppKit
import SwiftUI

/// Colors taken from the Wakey icon.
enum Brand {
    static let navy = Color(red: 0x2E / 255, green: 0x32 / 255, blue: 0x70 / 255)
    static let navyDark = Color(red: 0x36 / 255, green: 0x3B / 255, blue: 0x8C / 255)
    static let accent = Color(red: 0x4F / 255, green: 0x55 / 255, blue: 0xD8 / 255)
    static let lavender = Color(red: 0xA9 / 255, green: 0xAD / 255, blue: 0xF7 / 255)

    static func hero(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? navyDark : navy
    }

    /// The app icon from the bundle, or the generic one when run with `swift run`.
    static var appIcon: NSImage {
        if let url = Bundle.main.url(forResource: "WakeyIcon", withExtension: "png"),
           let image = NSImage(contentsOf: url) {
            return image
        }
        return NSApplication.shared.applicationIconImage ?? NSImage()
    }
}

struct AppIconView: View {
    var size: CGFloat

    var body: some View {
        Image(nsImage: Brand.appIcon)
            .resizable()
            .interpolation(.high)
            .frame(width: size, height: size)
            .accessibilityHidden(true)
    }
}

/// Moon, "z" and a slash, drawn as a template image so macOS tints it for the menu bar.
enum MenuBarIcon {
    static func image(active: Bool, lidMode: Bool) -> NSImage {
        let image = NSImage(size: NSSize(width: 18, height: 18), flipped: false) { _ in
            guard let context = NSGraphicsContext.current else { return false }
            let ink = NSColor.black.withAlphaComponent(active ? 1 : 0.45)

            // Crescent: a full moon with a smaller circle cut out of its upper right.
            ink.setFill()
            NSBezierPath(ovalIn: NSRect(x: 1.6, y: 1.4, width: 13.2, height: 13.2)).fill()
            context.compositingOperation = .clear
            NSBezierPath(ovalIn: NSRect(x: 6.2, y: 5.6, width: 11, height: 11)).fill()
            context.compositingOperation = .sourceOver

            // "z" in the upper right.
            ink.setStroke()
            let z = NSBezierPath()
            z.lineWidth = 1.4
            z.lineCapStyle = .round
            z.lineJoinStyle = .round
            z.move(to: NSPoint(x: 11.6, y: 16.2))
            z.line(to: NSPoint(x: 15.2, y: 16.2))
            z.line(to: NSPoint(x: 11.6, y: 12.2))
            z.line(to: NSPoint(x: 15.2, y: 12.2))
            z.stroke()

            // Slash across the moon, with a gap cut around it.
            let slash = NSBezierPath()
            slash.move(to: NSPoint(x: 2.2, y: 2.6))
            slash.line(to: NSPoint(x: 15.8, y: 11.4))
            slash.lineCapStyle = .round
            context.compositingOperation = .clear
            slash.lineWidth = 4
            slash.stroke()
            context.compositingOperation = .sourceOver
            slash.lineWidth = 1.8
            slash.stroke()

            if lidMode {
                ink.setFill()
                NSBezierPath(ovalIn: NSRect(x: 14.2, y: 0.6, width: 3.2, height: 3.2)).fill()
            }
            return true
        }
        image.isTemplate = true
        image.accessibilityDescription = "Wakey"
        return image
    }
}

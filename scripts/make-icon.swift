// Turns the source icon (navy square on a white background) into:
//   AppIcon.png      1024×1024, macOS icon grid (824 artwork, transparent margin)
//   icon-rounded.png  512×512, rounded corners, no margin (README, in-app)
//
//   swift scripts/make-icon.swift assets/icon.png assets
import AppKit

let arguments = CommandLine.arguments
guard arguments.count == 3,
      let source = NSImage(contentsOfFile: arguments[1]),
      let image = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    print("usage: swift make-icon.swift <source.png> <output-folder>")
    exit(1)
}
let outputFolder = URL(fileURLWithPath: arguments[2], isDirectory: true)

// Find the navy square: dark, bluish pixels. The white margin and grey shadow are left out.
let width = image.width, height = image.height
let space = CGColorSpaceCreateDeviceRGB()
guard let scan = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                           space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue),
      let pixels = scan.data?.bindMemory(to: UInt8.self, capacity: width * height * 4) else { exit(1) }
scan.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
var minX = width, minY = height, maxX = 0, maxY = 0
for y in 0..<height {
    for x in 0..<width {
        let i = (y * width + x) * 4
        let r = Int(pixels[i]), g = Int(pixels[i + 1]), b = Int(pixels[i + 2])
        if r + g + b < 360, b > r + 20 {
            minX = min(minX, x); maxX = max(maxX, x)
            minY = min(minY, y); maxY = max(maxY, y)
        }
    }
}
guard maxX > minX, maxY > minY,
      let artwork = image.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1)) else {
    print("Couldn't find the icon square")
    exit(1)
}

func write(size: Int, inset: CGFloat, to name: String) {
    guard let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: size * 4,
                                  space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return }
    context.interpolationQuality = .high
    let rect = CGRect(x: inset, y: inset, width: CGFloat(size) - inset * 2, height: CGFloat(size) - inset * 2)
    let radius = rect.width * 0.2237
    context.addPath(CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil))
    context.clip()
    // Scale up slightly so the source's own anti-aliased corners fall outside the clip.
    context.draw(artwork, in: rect.insetBy(dx: -rect.width * 0.01, dy: -rect.height * 0.01))
    guard let result = context.makeImage() else { return }
    let bitmap = NSBitmapImageRep(cgImage: result)
    let url = outputFolder.appendingPathComponent(name)
    try? bitmap.representation(using: .png, properties: [:])?.write(to: url)
    print("Wrote \(url.path)")
}

write(size: 1024, inset: 100, to: "AppIcon.png")
write(size: 512, inset: 0, to: "icon-rounded.png")

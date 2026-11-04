// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Wakey",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Wakey", targets: ["Wakey"]),
        .executable(name: "WakeyHelper", targets: ["WakeyHelper"])
    ],
    targets: [
        // Pure logic shared by the app, the helper and the tests.
        .target(name: "WakeyCore"),
        // Menu bar app.
        .executableTarget(name: "Wakey", dependencies: ["WakeyCore"]),
        // Privileged helper that turns lid mode (pmset disablesleep) on and off.
        .executableTarget(name: "WakeyHelper", dependencies: ["WakeyCore"]),
        .testTarget(name: "WakeyCoreTests", dependencies: ["WakeyCore"])
    ],
    swiftLanguageModes: [.v5]
)

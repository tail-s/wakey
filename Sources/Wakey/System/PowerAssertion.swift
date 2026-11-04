import Foundation
import IOKit.pwr_mgt

/// One IOKit power assertion that can be turned on and off. macOS releases it
/// automatically if Wakey quits or crashes.
final class PowerAssertion {
    private let type: String
    private let name: String
    private var assertionID: IOPMAssertionID = 0
    private(set) var isHeld = false

    init(type: String, name: String) {
        self.type = type
        self.name = name
    }

    /// Stage 4: idle system sleep.
    static func idleSleep() -> PowerAssertion {
        PowerAssertion(type: kIOPMAssertPreventUserIdleSystemSleep, name: "Wakey: keeping the Mac awake for AI work")
    }

    /// Stages 1–2: screen saver and display sleep.
    static func displaySleep() -> PowerAssertion {
        PowerAssertion(type: kIOPMAssertPreventUserIdleDisplaySleep, name: "Wakey: keeping the screen on")
    }

    func set(_ on: Bool) {
        if on, !isHeld {
            let result = IOPMAssertionCreateWithName(
                type as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                name as CFString,
                &assertionID
            )
            isHeld = result == kIOReturnSuccess
        } else if !on, isHeld {
            IOPMAssertionRelease(assertionID)
            isHeld = false
        }
    }

    deinit {
        if isHeld { IOPMAssertionRelease(assertionID) }
    }
}

enum DisplayControl {
    /// `pmset displaysleepnow`: turns the display off but keeps it connected,
    /// so clamshell mode survives. No admin rights needed.
    static func sleepDisplayNow() {
        run(["displaysleepnow"])
    }

    /// `pmset sleepnow`: used after lid mode ends with the lid closed and no display.
    static func sleepNow() {
        run(["sleepnow"])
    }

    /// Reads `SleepDisabled` from `pmset -g` (lid mode currently on or off).
    static func sleepDisabled() -> Bool {
        let output = run(["-g"], capture: true) ?? ""
        return output.split(separator: "\n").contains { line in
            let parts = line.split(whereSeparator: \.isWhitespace)
            return parts.first == "SleepDisabled" && parts.last == "1"
        }
    }

    @discardableResult
    private static func run(_ arguments: [String], capture: Bool = false) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = capture ? pipe : FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
        } catch {
            return nil
        }
        let data = capture ? pipe.fileHandleForReading.readDataToEndOfFile() : Data()
        process.waitUntilExit()
        return capture ? String(data: data, encoding: .utf8) : nil
    }
}

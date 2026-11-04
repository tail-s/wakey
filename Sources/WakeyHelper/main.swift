// Privileged helper for Wakey's lid mode.
//
// launchd starts it on demand (SMAppService daemon). It only does one thing:
// run `pmset -a disablesleep 0|1`. When the app's connection goes away for any
// reason (quit, crash, force quit) it turns lid mode off again.
import Foundation
import Security
import WakeyCore

let helperVersionString = "1"

enum Pmset {
    @discardableResult
    static func setSleepDisabled(_ on: Bool) -> (ok: Bool, message: String?) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pmset")
        process.arguments = ["-a", "disablesleep", on ? "1" : "0"]
        let errors = Pipe()
        process.standardError = errors
        process.standardOutput = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return (false, error.localizedDescription)
        }
        let message = String(data: errors.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return (process.terminationStatus == 0, message?.isEmpty == false ? message : nil)
    }
}

/// One per app connection.
final class LidSession: NSObject, WakeyHelperProtocol {
    private let lock = NSLock()
    private var enabled = false

    func setLidMode(_ on: Bool, withReply reply: @escaping (Bool, String?) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        let result = Pmset.setSleepDisabled(on)
        if result.ok { enabled = on }
        reply(result.ok, result.message)
    }

    func helperVersion(withReply reply: @escaping (String) -> Void) {
        reply(helperVersionString)
    }

    /// Called when the app disconnects.
    func connectionEnded() {
        lock.lock()
        defer { lock.unlock() }
        if enabled {
            Pmset.setSleepDisabled(false)
            enabled = false
        }
    }
}

final class ListenerDelegate: NSObject, NSXPCListenerDelegate {
    let requirement: String

    init(requirement: String) {
        self.requirement = requirement
    }

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        // Only the Wakey app signed by the same team may talk to the helper.
        connection.setCodeSigningRequirement(requirement)
        let session = LidSession()
        connection.exportedInterface = NSXPCInterface(with: WakeyHelperProtocol.self)
        connection.exportedObject = session
        connection.invalidationHandler = { session.connectionEnded() }
        connection.interruptionHandler = { session.connectionEnded() }
        connection.resume()
        return true
    }
}

func ownTeamIdentifier() -> String? {
    var code: SecCode?
    guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
    var staticCode: SecStaticCode?
    guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
    var info: CFDictionary?
    guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
          let dictionary = info as? [String: Any] else { return nil }
    return dictionary[kSecCodeInfoTeamIdentifier as String] as? String
}

// launchd only starts the helper when the app connects, so nobody can be
// holding lid mode yet. Undo anything a previous run left behind.
Pmset.setSleepDisabled(false)

let delegate = ListenerDelegate(
    requirement: wakeyPeerRequirement(identifier: wakeyBundleIdentifier, teamID: ownTeamIdentifier())
)
let listener = NSXPCListener(machServiceName: wakeyHelperMachService)
listener.delegate = delegate
listener.resume()
RunLoop.main.run()

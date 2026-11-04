import AppKit
import Security
import ServiceManagement
import WakeyCore

/// Installs the privileged helper and asks it to turn lid mode on and off.
@MainActor
final class LidController: ObservableObject {
    enum HelperStatus: Equatable {
        case notInstalled
        case needsApproval
        case ready
        /// No helper in this build (for example `swift run`, or not signed).
        case unavailable
    }

    @Published private(set) var status: HelperStatus = .unavailable
    @Published private(set) var isOn = false
    @Published private(set) var lastError: String?

    private let service = SMAppService.daemon(plistName: wakeyHelperPlistName)
    private var connection: NSXPCConnection?
    private var pending: Bool?

    var onStateChange: (() -> Void)?

    func refreshStatus() {
        let newStatus: HelperStatus
        switch service.status {
        case .enabled: newStatus = .ready
        case .requiresApproval: newStatus = .needsApproval
        case .notRegistered: newStatus = .notInstalled
        // macOS also reports notFound for a daemon that was never registered.
        case .notFound: newStatus = Self.helperIsBundled ? .notInstalled : .unavailable
        @unknown default: newStatus = .unavailable
        }
        if newStatus != status {
            status = newStatus
            onStateChange?()
        }
    }

    func install() {
        lastError = nil
        do {
            try service.register()
        } catch {
            lastError = error.localizedDescription
        }
        refreshStatus()
        if status == .needsApproval {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    func uninstall() {
        set(false)
        Task {
            do {
                try await service.unregister()
            } catch {
                lastError = error.localizedDescription
            }
            refreshStatus()
        }
    }

    func openLoginItems() {
        SMAppService.openSystemSettingsLoginItems()
    }

    /// Turns lid mode on or off through the helper. Safe to call repeatedly.
    func set(_ on: Bool) {
        guard status == .ready else {
            if !on { isOn = false }
            return
        }
        guard on != isOn, pending != on else { return }
        pending = on
        let proxy = helperConnection().remoteObjectProxyWithErrorHandler { [weak self] error in
            Task { @MainActor in
                self?.pending = nil
                self?.lastError = error.localizedDescription
            }
        } as? WakeyHelperProtocol
        proxy?.setLidMode(on) { [weak self] ok, message in
            Task { @MainActor in
                guard let self else { return }
                self.pending = nil
                if ok {
                    self.isOn = on
                    self.lastError = nil
                } else {
                    self.lastError = message
                }
                if !on, ok {
                    // Nothing to keep alive; dropping the connection is harmless.
                    self.connection?.invalidate()
                    self.connection = nil
                }
                self.onStateChange?()
            }
        }
    }

    /// Turns lid mode off even if this run never turned it on (left over from a crash).
    func forceOff() {
        guard status == .ready else { return }
        let proxy = helperConnection().remoteObjectProxyWithErrorHandler { [weak self] error in
            Task { @MainActor in self?.lastError = error.localizedDescription }
        } as? WakeyHelperProtocol
        proxy?.setLidMode(false) { [weak self] _, _ in
            Task { @MainActor in self?.isOn = false }
        }
    }

    /// Turns lid mode off before Wakey quits. Waits briefly for the helper.
    func turnOffSynchronously() {
        guard isOn, status == .ready else { return }
        let done = DispatchSemaphore(value: 0)
        let proxy = helperConnection().remoteObjectProxyWithErrorHandler { _ in done.signal() } as? WakeyHelperProtocol
        proxy?.setLidMode(false) { _, _ in done.signal() }
        _ = done.wait(timeout: .now() + 2)
        isOn = false
    }

    private func helperConnection() -> NSXPCConnection {
        if let connection { return connection }
        let connection = NSXPCConnection(machServiceName: wakeyHelperMachService, options: .privileged)
        connection.remoteObjectInterface = NSXPCInterface(with: WakeyHelperProtocol.self)
        connection.setCodeSigningRequirement(
            wakeyPeerRequirement(identifier: wakeyHelperIdentifier, teamID: Self.ownTeamIdentifier())
        )
        // If the helper goes away it has already turned lid mode off.
        let reset: @Sendable () -> Void = { [weak self] in
            Task { @MainActor in
                self?.connection = nil
                self?.isOn = false
                self?.pending = nil
                self?.onStateChange?()
            }
        }
        connection.invalidationHandler = reset
        connection.interruptionHandler = reset
        connection.resume()
        self.connection = connection
        return connection
    }

    /// The helper and its launchd plist exist only in the assembled app bundle.
    private static var helperIsBundled: Bool {
        let contents = Bundle.main.bundleURL.appendingPathComponent("Contents")
        let fileManager = FileManager.default
        return fileManager.fileExists(atPath: contents.appendingPathComponent("Library/LaunchDaemons/\(wakeyHelperPlistName)").path)
            && fileManager.fileExists(atPath: contents.appendingPathComponent("MacOS/WakeyHelper").path)
    }

    private static func ownTeamIdentifier() -> String? {
        var code: SecCode?
        guard SecCodeCopySelf([], &code) == errSecSuccess, let code else { return nil }
        var staticCode: SecStaticCode?
        guard SecCodeCopyStaticCode(code, [], &staticCode) == errSecSuccess, let staticCode else { return nil }
        var info: CFDictionary?
        guard SecCodeCopySigningInformation(staticCode, SecCSFlags(rawValue: kSecCSSigningInformation), &info) == errSecSuccess,
              let dictionary = info as? [String: Any] else { return nil }
        return dictionary[kSecCodeInfoTeamIdentifier as String] as? String
    }
}

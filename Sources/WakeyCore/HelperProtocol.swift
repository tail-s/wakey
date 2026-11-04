import Foundation

public let wakeyBundleIdentifier = "app.wakey.Wakey"
public let wakeyHelperIdentifier = "app.wakey.Wakey.helper"
public let wakeyHelperMachService = "app.wakey.Wakey.helper"
public let wakeyHelperPlistName = "app.wakey.Wakey.helper.plist"

/// XPC interface of the privileged helper. The helper turns lid mode off by
/// itself when the app's connection goes away, so a crash never leaves the
/// Mac unable to sleep.
@objc public protocol WakeyHelperProtocol {
    func setLidMode(_ on: Bool, withReply reply: @escaping (Bool, String?) -> Void)
    func helperVersion(withReply reply: @escaping (String) -> Void)
}

/// Code signing requirement that the other side of the XPC connection must meet.
public func wakeyPeerRequirement(identifier: String, teamID: String?) -> String {
    guard let teamID, !teamID.isEmpty else {
        // Ad hoc builds have no team; only the identifier can be checked.
        return "identifier \"\(identifier)\""
    }
    return "identifier \"\(identifier)\" and anchor apple generic and certificate leaf[subject.OU] = \"\(teamID)\""
}

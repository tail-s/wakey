import Foundation
import WakeyCore

/// Writes Wakey's hook script and adds or removes the hooks in
/// `~/.claude/settings.json`. Only runs when the user asks in Settings.
enum ClaudeHookInstaller {
    enum InstallError: LocalizedError {
        case unreadableSettings

        var errorDescription: String? {
            "~/.claude/settings.json isn’t valid JSON, so Wakey left it unchanged."
        }
    }

    private static var home: URL { FileManager.default.homeDirectoryForCurrentUser }
    static var supportDirectory: URL { home.appendingPathComponent("Library/Application Support/Wakey") }
    static var scriptURL: URL { supportDirectory.appendingPathComponent(ClaudeHooks.scriptName) }
    static var sessionsDirectory: URL { supportDirectory.appendingPathComponent("claude-sessions") }
    static var settingsURL: URL { home.appendingPathComponent(".claude/settings.json") }
    static var backupURL: URL { home.appendingPathComponent(".claude/settings.json.wakey-backup") }

    /// A session older than this is assumed to have crashed without a Stop hook.
    static let staleAfter: TimeInterval = 6 * 60 * 60

    static func isInstalled() -> Bool {
        guard let settings = try? readSettings() else { return false }
        return ClaudeHooks.isInstalled(in: settings)
    }

    static func install() throws {
        let fileManager = FileManager.default
        try fileManager.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        try ClaudeHooks.script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)

        let settings = try readSettings()
        if fileManager.fileExists(atPath: settingsURL.path), !fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.copyItem(at: settingsURL, to: backupURL)
        }
        try writeSettings(ClaudeHooks.installing(into: settings, scriptPath: scriptURL.path))
    }

    static func remove() throws {
        try writeSettings(ClaudeHooks.removing(from: readSettings()))
        try? FileManager.default.removeItem(at: sessionsDirectory)
    }

    /// True when at least one Claude Code session has started and not finished.
    static func hasActiveSession() -> Bool {
        let fileManager = FileManager.default
        guard let files = try? fileManager.contentsOfDirectory(
            at: sessionsDirectory, includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return false }
        var active = false
        for file in files {
            let modified = (try? file.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate ?? .distantPast
            if Date().timeIntervalSince(modified) > staleAfter {
                try? fileManager.removeItem(at: file)
            } else {
                active = true
            }
        }
        return active
    }

    private static func readSettings() throws -> [String: Any] {
        guard let data = try? Data(contentsOf: settingsURL), !data.isEmpty else { return [:] }
        guard let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw InstallError.unreadableSettings
        }
        return object
    }

    private static func writeSettings(_ settings: [String: Any]) throws {
        try FileManager.default.createDirectory(at: settingsURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONSerialization.data(
            withJSONObject: settings, options: [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        )
        try data.write(to: settingsURL, options: .atomic)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: settingsURL.path)
    }
}

import Foundation

/// Adds and removes Wakey's Claude Code hooks in a parsed `~/.claude/settings.json`.
///
/// The hooks run a small script that writes one marker file per working
/// session (on `UserPromptSubmit`) and deletes it when Claude finishes
/// (`Stop`) or the session ends (`SessionEnd`). Wakey treats any marker as
/// "Claude Code is working".
public enum ClaudeHooks {
    /// Every command Wakey adds contains this, so it can find its own hooks again.
    public static let scriptName = "wakey-claude-hook.sh"

    public static let events: [(event: String, action: String)] = [
        ("UserPromptSubmit", "start"),
        ("Stop", "stop"),
        ("SessionEnd", "stop")
    ]

    public static func command(scriptPath: String, action: String) -> String {
        "\"\(scriptPath)\" \(action)"
    }

    public static func isInstalled(in settings: [String: Any]) -> Bool {
        guard let hooks = settings["hooks"] as? [String: Any] else { return false }
        return events.allSatisfy { entry in
            guard let groups = hooks[entry.event] as? [[String: Any]] else { return false }
            return groups.contains { group in
                commands(in: group).contains { $0.contains(scriptName) }
            }
        }
    }

    public static func installing(into settings: [String: Any], scriptPath: String) -> [String: Any] {
        var result = removing(from: settings)
        var hooks = result["hooks"] as? [String: Any] ?? [:]
        for entry in events {
            var groups = hooks[entry.event] as? [[String: Any]] ?? []
            groups.append([
                "hooks": [["type": "command", "command": command(scriptPath: scriptPath, action: entry.action)]]
            ])
            hooks[entry.event] = groups
        }
        result["hooks"] = hooks
        return result
    }

    /// Removes only Wakey's hooks and leaves everything else as it was.
    public static func removing(from settings: [String: Any]) -> [String: Any] {
        var result = settings
        guard var hooks = settings["hooks"] as? [String: Any] else { return result }
        for (event, value) in hooks {
            guard let groups = value as? [[String: Any]] else { continue }
            var kept: [[String: Any]] = []
            for var group in groups {
                guard let entries = group["hooks"] as? [[String: Any]] else {
                    kept.append(group)
                    continue
                }
                let others = entries.filter { !(($0["command"] as? String) ?? "").contains(scriptName) }
                if others.isEmpty { continue }
                group["hooks"] = others
                kept.append(group)
            }
            hooks[event] = kept.isEmpty ? nil : kept
        }
        result["hooks"] = hooks.isEmpty ? nil : hooks
        return result
    }

    private static func commands(in group: [String: Any]) -> [String] {
        (group["hooks"] as? [[String: Any]] ?? []).compactMap { $0["command"] as? String }
    }

    /// The script the hooks run. It only writes and deletes marker files.
    public static let script = """
    #!/bin/sh
    # Wakey: marks a Claude Code session as working (start) or finished (stop).
    # It reads the hook input only to find the session id.
    dir="$HOME/Library/Application Support/Wakey/claude-sessions"
    mkdir -p "$dir"
    id=$(sed -n 's/.*"session_id"[[:space:]]*:[[:space:]]*"\\([^"]*\\)".*/\\1/p' | head -n 1 | tr -cd 'A-Za-z0-9._-')
    [ -n "$id" ] || id="unknown"
    case "$1" in
      start) date +%s > "$dir/$id" ;;
      stop) rm -f "$dir/$id" ;;
    esac
    exit 0

    """
}

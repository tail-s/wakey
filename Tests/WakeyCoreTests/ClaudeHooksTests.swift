import Foundation
import Testing
@testable import WakeyCore

@Suite struct ClaudeHooksTests {
    let script = "/Users/me/Library/Application Support/Wakey/wakey-claude-hook.sh"

    @Test func installsIntoEmptySettings() {
        let result = ClaudeHooks.installing(into: ["skipWorkflowUsageWarning": true], scriptPath: script)
        #expect(ClaudeHooks.isInstalled(in: result))
        #expect(result["skipWorkflowUsageWarning"] as? Bool == true)
        let stop = (result["hooks"] as? [String: Any])?["Stop"] as? [[String: Any]]
        let command = (stop?.first?["hooks"] as? [[String: Any]])?.first?["command"] as? String
        #expect(command == "\"\(script)\" stop")
    }

    @Test func keepsOtherHooksAndDoesNotDuplicate() {
        let existing: [String: Any] = [
            "hooks": [
                "Stop": [["hooks": [["type": "command", "command": "afplay /System/Library/Sounds/Glass.aiff"]]]],
                "PreToolUse": [["matcher": "Bash", "hooks": [["type": "command", "command": "echo hi"]]]]
            ]
        ]
        let once = ClaudeHooks.installing(into: existing, scriptPath: script)
        let twice = ClaudeHooks.installing(into: once, scriptPath: script)
        let hooks = twice["hooks"] as? [String: Any]
        #expect((hooks?["Stop"] as? [[String: Any]])?.count == 2)
        #expect((hooks?["PreToolUse"] as? [[String: Any]])?.count == 1)
        #expect((hooks?["UserPromptSubmit"] as? [[String: Any]])?.count == 1)
    }

    @Test func removingRestoresOriginal() {
        let original: [String: Any] = [
            "model": "opus",
            "hooks": ["Stop": [["hooks": [["type": "command", "command": "echo done"]]]]]
        ]
        let installed = ClaudeHooks.installing(into: original, scriptPath: script)
        let removed = ClaudeHooks.removing(from: installed)
        #expect(!ClaudeHooks.isInstalled(in: removed))
        #expect(NSDictionary(dictionary: removed).isEqual(to: original))
    }

    @Test func removingFromSettingsWithoutHooksLeavesNoHooksKey() {
        let installed = ClaudeHooks.installing(into: [:], scriptPath: script)
        let removed = ClaudeHooks.removing(from: installed)
        #expect(removed["hooks"] == nil)
    }
}

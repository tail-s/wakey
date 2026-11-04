import AppKit
import Darwin
import IOKit.pwr_mgt

enum AIApp: String, CaseIterable, Identifiable {
    case claude, chatGPT, antigravity, terminal
    var id: String { rawValue }
}

/// Which apps the user wants Wakey to watch (Settings › Detection).
struct WatchSettings: Equatable {
    var claude = true
    var chatGPT = true
    var antigravity = true
    var terminal = true

    subscript(app: AIApp) -> Bool {
        get {
            switch app {
            case .claude: return claude
            case .chatGPT: return chatGPT
            case .antigravity: return antigravity
            case .terminal: return terminal
            }
        }
        set {
            switch app {
            case .claude: claude = newValue
            case .chatGPT: chatGPT = newValue
            case .antigravity: antigravity = newValue
            case .terminal: terminal = newValue
            }
        }
    }
}

struct AIStatus: Equatable {
    var working: Set<AIApp> = []
    var running: Set<AIApp> = []
    /// AI apps that hold their own idle-sleep assertion right now.
    var holdingSleep: Set<AIApp> = []

    var isWorking: Bool { !working.isEmpty }
}

/// Decides whether AI apps are working, from the strongest signal available:
/// 1. the app's own sleep assertion (Claude, ChatGPT/Codex),
/// 2. Claude Code hook markers (exact start and finish),
/// 3. CPU activity of agent processes (Antigravity, terminal agents).
final class AIDetector {
    static let claudeBundleID = "com.anthropic.claudefordesktop"
    static let chatGPTBundleID = "com.openai.codex"
    static let antigravityBundleID = "com.google.antigravity"
    /// Percent of one CPU core that counts as "working".
    static let cpuThreshold = 3.0

    private var lastCPU: [pid_t: UInt64] = [:]
    private var lastSampleTime: UInt64 = 0
    private let timebase: mach_timebase_info_data_t

    init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        timebase = info
    }

    func sample(watch: WatchSettings) -> AIStatus {
        var status = AIStatus()

        let running = Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
        if running.contains(Self.claudeBundleID) { status.running.insert(.claude) }
        if running.contains(Self.chatGPTBundleID) { status.running.insert(.chatGPT) }
        if running.contains(Self.antigravityBundleID) { status.running.insert(.antigravity) }

        let holders = Self.bundleIDsHoldingIdleSleep()
        if holders.contains(Self.claudeBundleID) { status.holdingSleep.insert(.claude) }
        if holders.contains(Self.chatGPTBundleID) { status.holdingSleep.insert(.chatGPT) }
        if watch.claude, status.holdingSleep.contains(.claude) || ClaudeHookInstaller.hasActiveSession() {
            status.working.insert(.claude)
        }
        if watch.chatGPT, status.holdingSleep.contains(.chatGPT) {
            status.working.insert(.chatGPT)
        }

        let now = clock_gettime_nsec_np(CLOCK_UPTIME_RAW)
        let elapsed = lastSampleTime == 0 ? 0 : now - lastSampleTime
        var cpuNow: [pid_t: UInt64] = [:]
        for process in Self.processes() {
            let isAntigravity = process.path.contains("/Antigravity.app/") && process.name.hasPrefix("language_server")
            // Agents bundled inside apps (Claude desktop, ChatGPT) are covered above.
            let isTerminal = (process.name == "claude" || process.name == "codex") && !process.path.contains(".app/")
            guard isAntigravity || isTerminal else { continue }
            if isTerminal { status.running.insert(.terminal) }
            guard let cpu = cpuTimeNanoseconds(process.pid) else { continue }
            cpuNow[process.pid] = cpu
            guard elapsed > 0, let before = lastCPU[process.pid], cpu >= before else { continue }
            let percent = Double(cpu - before) / Double(elapsed) * 100
            guard percent >= Self.cpuThreshold else { continue }
            if isAntigravity, watch.antigravity { status.working.insert(.antigravity) }
            if isTerminal, watch.terminal { status.working.insert(.terminal) }
        }
        lastCPU = cpuNow
        lastSampleTime = now
        return status
    }

    private func cpuTimeNanoseconds(_ pid: pid_t) -> UInt64? {
        var info = proc_taskinfo()
        let size = Int32(MemoryLayout<proc_taskinfo>.size)
        guard proc_pidinfo(pid, PROC_PIDTASKINFO, 0, &info, size) == size else { return nil }
        let ticks = info.pti_total_user + info.pti_total_system
        return ticks * UInt64(timebase.numer) / UInt64(timebase.denom)
    }

    private static func processes() -> [(pid: pid_t, path: String, name: String)] {
        let estimate = proc_listallpids(nil, 0)
        guard estimate > 0 else { return [] }
        var pids = [pid_t](repeating: 0, count: Int(estimate) + 64)
        let count = proc_listallpids(&pids, Int32(pids.count * MemoryLayout<pid_t>.size))
        guard count > 0 else { return [] }
        var buffer = [CChar](repeating: 0, count: 4096)
        var result: [(pid: pid_t, path: String, name: String)] = []
        for pid in pids.prefix(Int(count)) where pid > 0 {
            guard proc_pidpath(pid, &buffer, UInt32(buffer.count)) > 0 else { continue }
            let path = String(cString: buffer)
            result.append((pid, path, (path as NSString).lastPathComponent))
        }
        return result
    }

    private static func bundleIDsHoldingIdleSleep() -> Set<String> {
        var unmanaged: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&unmanaged) == kIOReturnSuccess,
              let byPID = unmanaged?.takeRetainedValue() as? [NSNumber: [[String: Any]]] else { return [] }
        let idleTypes: Set<String> = ["PreventUserIdleSystemSleep", "NoIdleSleepAssertion", "PreventSystemSleep"]
        var result = Set<String>()
        for (pid, assertions) in byPID {
            let holdsIdle = assertions.contains { idleTypes.contains(($0[kIOPMAssertionTypeKey] as? String) ?? "") }
            if holdsIdle, let bundleID = NSRunningApplication(processIdentifier: pid.int32Value)?.bundleIdentifier {
                result.insert(bundleID)
            }
        }
        return result
    }
}

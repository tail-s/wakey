import AppKit
import Combine
import SwiftUI
import WakeyCore

enum TimerChoice: String, CaseIterable, Identifiable {
    case minutes30, hour1, hours2, always
    var id: String { rawValue }

    var minutes: Int? {
        switch self {
        case .minutes30: return 30
        case .hour1: return 60
        case .hours2: return 120
        case .always: return nil
        }
    }

    var labelKey: L10nKey {
        switch self {
        case .minutes30: return .timer30
        case .hour1: return .timer60
        case .hours2: return .timer120
        case .always: return .timerAlways
        }
    }
}

/// Holds preferences, reads the Mac's state, asks the engine what to block and applies it.
@MainActor
final class AppModel: ObservableObject {
    static let shared = AppModel(applyEffects: true)

    // MARK: Preferences (saved)
    @Published var language: AppLanguage { didSet { preferencesChanged() } }
    @Published var appearance: AppearanceMode { didSet { preferencesChanged(); applyAppearance() } }
    @Published var autoEnabled: Bool { didSet { preferencesChanged() } }
    @Published var lidAway: Bool { didSet { preferencesChanged() } }
    @Published var keepOnBattery: Bool { didSet { preferencesChanged() } }
    @Published var remoteStandby: Bool { didSet { preferencesChanged() } }
    @Published var clamshellAuto: Bool { didSet { preferencesChanged() } }
    @Published var thermalGuard: Bool { didSet { preferencesChanged() } }
    @Published var batteryFloor: Int { didSet { preferencesChanged() } }
    @Published var releaseMinutes: Int { didSet { preferencesChanged() } }
    @Published var watch: WatchSettings { didSet { preferencesChanged() } }

    // MARK: Session only (lid mode must never survive a restart by surprise)
    @Published var manualIdle = false { didSet { setNeedsRefresh() } }
    @Published var manualDisplay = false { didSet { setNeedsRefresh() } }
    @Published var manualLid = false { didSet { setNeedsRefresh() } }
    @Published var timer: TimerChoice = .always {
        didSet {
            timerEnd = timer.minutes.map { Date().addingTimeInterval(TimeInterval($0 * 60)) }
            setNeedsRefresh()
        }
    }
    @Published private(set) var timerEnd: Date?
    @Published private(set) var awayHold = false

    // MARK: Detected state
    @Published private(set) var system = SystemState()
    @Published private(set) var ai = AIStatus()
    @Published private(set) var decision = Decision()
    @Published private(set) var hooksInstalled = false
    @Published private(set) var hooksError: String?
    @Published private(set) var launchAtLogin = false
    @Published private(set) var launchAtLoginFailed = false

    let lid = LidController()

    private let applyEffects: Bool
    private let defaults = UserDefaults.standard
    private let detector = AIDetector()
    private let idleAssertion = PowerAssertion.idleSleep()
    private let displayAssertion = PowerAssertion.displaySleep()
    private var monitor: SystemMonitor?
    private var pollTimer: Timer?
    private var lastWorkingAt: Date?
    private var refreshScheduled = false
    private var observers: [NSObjectProtocol] = []
    private var lidChanges: AnyCancellable?
    private var activity: NSObjectProtocol?

    init(applyEffects: Bool) {
        self.applyEffects = applyEffects
        let stored = UserDefaults.standard
        stored.register(defaults: [
            Keys.language: AppLanguage.english.rawValue,
            Keys.appearance: AppearanceMode.system.rawValue,
            Keys.autoEnabled: true,
            Keys.lidAway: false,
            Keys.keepOnBattery: false,
            Keys.remoteStandby: false,
            Keys.clamshellAuto: true,
            Keys.thermalGuard: true,
            Keys.batteryFloor: 20,
            Keys.releaseMinutes: 5,
            Keys.watchClaude: true,
            Keys.watchChatGPT: true,
            Keys.watchAntigravity: true,
            Keys.watchTerminal: true
        ])
        language = AppLanguage(rawValue: stored.string(forKey: Keys.language) ?? "") ?? .english
        appearance = AppearanceMode(rawValue: stored.string(forKey: Keys.appearance) ?? "") ?? .system
        autoEnabled = stored.bool(forKey: Keys.autoEnabled)
        lidAway = stored.bool(forKey: Keys.lidAway)
        keepOnBattery = stored.bool(forKey: Keys.keepOnBattery)
        remoteStandby = stored.bool(forKey: Keys.remoteStandby)
        clamshellAuto = stored.bool(forKey: Keys.clamshellAuto)
        thermalGuard = stored.bool(forKey: Keys.thermalGuard)
        batteryFloor = stored.integer(forKey: Keys.batteryFloor)
        releaseMinutes = stored.integer(forKey: Keys.releaseMinutes)
        watch = WatchSettings(
            claude: stored.bool(forKey: Keys.watchClaude),
            chatGPT: stored.bool(forKey: Keys.watchChatGPT),
            antigravity: stored.bool(forKey: Keys.watchAntigravity),
            terminal: stored.bool(forKey: Keys.watchTerminal)
        )
        lidChanges = lid.objectWillChange.sink { [weak self] _ in self?.objectWillChange.send() }
        lid.onStateChange = { [weak self] in self?.setNeedsRefresh() }
    }

    // MARK: Lifecycle

    func start() {
        applyAppearance()
        // Keep polling reliably while the Mac is idle (no App Nap). Sleep is still allowed.
        activity = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiatedAllowingIdleSystemSleep],
            reason: "Wakey watches the lid, power and AI activity"
        )
        hooksInstalled = ClaudeHookInstaller.isInstalled()
        launchAtLogin = LoginItem.isEnabled
        lid.refreshStatus()
        // Undo lid mode left on by an earlier run.
        if applyEffects, lid.status == .ready, DisplayControl.sleepDisabled() {
            lid.forceOff()
        }

        let monitor = SystemMonitor { [weak self] in self?.setNeedsRefresh() }
        monitor.start()
        self.monitor = monitor

        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(workspace.addObserver(forName: NSWorkspace.screensDidWakeNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in self?.endAwayHold() }
        })

        sampleAI()
        let timer = Timer(timeInterval: 5, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        pollTimer = timer
        refresh()
    }

    func shutdown() {
        pollTimer?.invalidate()
        idleAssertion.set(false)
        displayAssertion.set(false)
        lid.turnOffSynchronously()
        if let activity { ProcessInfo.processInfo.endActivity(activity) }
    }

    /// Two AI samples a second apart, for the command-line status report and snapshots.
    func sampleNow() {
        system = SystemProbe.read()
        lid.refreshStatus()
        hooksInstalled = ClaudeHookInstaller.isInstalled()
        launchAtLogin = LoginItem.isEnabled
        sampleAI()
        Thread.sleep(forTimeInterval: 1)
        sampleAI()
        refresh()
    }

    private func tick() {
        sampleAI()
        refresh()
    }

    private func sampleAI() {
        ai = detector.sample(watch: watch)
    }

    // MARK: Actions

    func stepAway() {
        awayHold = true
        refresh()
        DisplayControl.sleepDisplayNow()
    }

    private func endAwayHold() {
        guard awayHold else { return }
        awayHold = false
        refresh()
    }

    func setLaunchAtLogin(_ on: Bool) {
        launchAtLoginFailed = !LoginItem.set(on)
        launchAtLogin = LoginItem.isEnabled
    }

    func installHooks() {
        do {
            try ClaudeHookInstaller.install()
            hooksError = nil
        } catch {
            hooksError = error.localizedDescription
        }
        hooksInstalled = ClaudeHookInstaller.isInstalled()
    }

    func removeHooks() {
        do {
            try ClaudeHookInstaller.remove()
            hooksError = nil
        } catch {
            hooksError = error.localizedDescription
        }
        hooksInstalled = ClaudeHookInstaller.isInstalled()
    }

    func openSettings() {
        SettingsWindowController.shared.show(model: self)
    }

    func openBundledDocument(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "md") else { return }
        NSWorkspace.shared.open(url)
    }

    // MARK: Decide and apply

    func setNeedsRefresh() {
        guard !refreshScheduled else { return }
        refreshScheduled = true
        DispatchQueue.main.async { [weak self] in
            self?.refreshScheduled = false
            self?.refresh()
        }
    }

    func refresh() {
        let now = Date()
        if let end = timerEnd, now >= end {
            expireTimer()
        }
        system = SystemProbe.read()
        lid.refreshStatus()

        if ai.isWorking { lastWorkingAt = now }
        let recentlyWorking = lastWorkingAt.map { now.timeIntervalSince($0) < TimeInterval(releaseMinutes * 60) } ?? false

        var input = EngineInput()
        input.autoEnabled = autoEnabled
        input.remoteStandby = remoteStandby
        input.keepOnBattery = keepOnBattery
        input.batteryFloor = batteryFloor
        input.lidAway = lidAway
        input.clamshellAuto = clamshellAuto
        input.thermalGuard = thermalGuard
        input.manualIdle = manualIdle
        input.manualDisplay = manualDisplay
        input.manualLid = manualLid
        input.awayHold = awayHold
        input.aiWorking = ai.isWorking || recentlyWorking
        input.onBattery = system.onBattery
        input.batteryPercent = system.batteryPercent
        input.lidClosed = system.lidClosed
        input.externalDisplay = system.externalDisplay
        input.thermalHot = system.thermalHot
        input.helperReady = lid.status == .ready

        let previous = decision
        let next = Engine.decide(input)
        if next != previous { decision = next }

        guard applyEffects else { return }
        idleAssertion.set(next.holdIdle)
        displayAssertion.set(next.holdDisplay)
        lid.set(next.lidMode)
        // "Keep going with the lid closed": once the work is done, sleep right away.
        if previous.lidMode, !next.lidMode, system.lidClosed, !system.externalDisplay {
            DisplayControl.sleepNow()
        }
    }

    private func expireTimer() {
        timerEnd = nil
        timer = .always
        manualIdle = false
        manualDisplay = false
        manualLid = false
        autoEnabled = false
    }

    private func preferencesChanged() {
        defaults.set(language.rawValue, forKey: Keys.language)
        defaults.set(appearance.rawValue, forKey: Keys.appearance)
        defaults.set(autoEnabled, forKey: Keys.autoEnabled)
        defaults.set(lidAway, forKey: Keys.lidAway)
        defaults.set(keepOnBattery, forKey: Keys.keepOnBattery)
        defaults.set(remoteStandby, forKey: Keys.remoteStandby)
        defaults.set(clamshellAuto, forKey: Keys.clamshellAuto)
        defaults.set(thermalGuard, forKey: Keys.thermalGuard)
        defaults.set(batteryFloor, forKey: Keys.batteryFloor)
        defaults.set(releaseMinutes, forKey: Keys.releaseMinutes)
        defaults.set(watch.claude, forKey: Keys.watchClaude)
        defaults.set(watch.chatGPT, forKey: Keys.watchChatGPT)
        defaults.set(watch.antigravity, forKey: Keys.watchAntigravity)
        defaults.set(watch.terminal, forKey: Keys.watchTerminal)
        setNeedsRefresh()
    }

    private func applyAppearance() {
        guard NSApp != nil else { return }
        switch appearance {
        case .system: NSApp.appearance = nil
        case .light: NSApp.appearance = NSAppearance(named: .aqua)
        case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
        }
    }

    // MARK: Text for the views

    func t(_ key: L10nKey) -> String { L10n.string(key, language) }

    func f(_ key: L10nKey, _ arguments: CVarArg...) -> String {
        String(format: t(key), locale: Locale(identifier: language.rawValue), arguments: arguments)
    }

    var colorScheme: ColorScheme? {
        switch appearance {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func name(of app: AIApp) -> String {
        switch app {
        case .claude: return "Claude"
        case .chatGPT: return "ChatGPT"
        case .antigravity: return "Antigravity"
        case .terminal: return t(.terminalAgentName)
        }
    }

    private var workingNames: String {
        AIApp.allCases.filter { ai.working.contains($0) }.map(name(of:)).joined(separator: ", ")
    }

    var heroLine: String {
        if !autoEnabled { return t(.heroOff) }
        if ai.isWorking { return f(.heroWorkingFormat, workingNames) }
        return remoteStandby ? t(.heroRemote) : t(.heroIdle)
    }

    var holdText: String {
        var parts: [String] = []
        if decision.holdIdle { parts.append(t(.holdIdle)) }
        if decision.holdDisplay { parts.append(t(.holdDisplay)) }
        if decision.lidMode { parts.append(t(.holdLid)) }
        return parts.isEmpty ? t(.nothing) : parts.joined(separator: " + ")
    }

    var reasonText: String {
        switch decision.reason {
        case .autoOff: return t(.reasonAutoOff)
        case .idle: return t(.reasonIdle)
        case .pausedOnBattery: return t(.reasonPausedOnBattery)
        case .batteryFloor: return t(.reasonBatteryFloor)
        case .remoteStandby: return t(.reasonRemoteStandby)
        case .clamshell: return t(.reasonClamshell)
        case .lidAway: return t(.reasonLidAway)
        case .normal: return t(.reasonNormal)
        }
    }

    /// Extra warning shown under the lid section, if any.
    var lidNote: String? {
        if decision.lidNeedsHelper { return t(.lidNeedsHelper) }
        if decision.lidBlockedByHeat { return t(.lidTooHot) }
        return nil
    }

    var situationText: String {
        switch Situation(lidClosed: system.lidClosed, externalDisplay: system.externalDisplay, onBattery: system.onBattery) {
        case .lidOpenAC: return t(.situationLidOpenAC)
        case .lidOpenBattery: return t(.situationLidOpenBattery)
        case .clamshell: return t(.situationClamshell)
        case .lidClosedNoDisplay: return t(.situationLidClosedNoDisplay)
        }
    }

    var powerText: String {
        let percent = system.batteryPercent ?? 0
        if system.onBattery { return f(.powerBatteryFormat, percent) }
        return system.hasBattery ? f(.powerACBatteryFormat, percent) : t(.powerAC)
    }

    var lidText: String {
        switch (system.lidClosed, system.externalDisplay) {
        case (true, true): return t(.lidClosedExternal)
        case (false, true): return t(.lidOpenExternal)
        case (false, false): return t(.lidOpenNoExternal)
        case (true, false): return t(.situationLidClosedNoDisplay)
        }
    }

    var detectedText: String {
        ai.isWorking ? f(.detectedWorkingFormat, workingNames) : t(.detectedNone)
    }

    var blockingText: String {
        var names = AIApp.allCases.filter { ai.holdingSleep.contains($0) }.map(name(of:))
        if decision.isActive { names.append("Wakey") }
        return f(.blockingFormat, names.isEmpty ? t(.nothing) : names.joined(separator: ", "))
    }

    var timerText: String {
        guard let end = timerEnd else { return t(.timerUntilOff) }
        let minutes = max(1, Int((end.timeIntervalSinceNow / 60).rounded(.up)))
        return f(.timerMinutesLeftFormat, minutes)
    }

    func statusText(for app: AIApp) -> String {
        if ai.working.contains(app) { return t(.statusWorking) }
        return ai.running.contains(app) ? t(.statusIdle) : t(.statusNotRunning)
    }

    var helperStatusText: String {
        switch lid.status {
        case .ready: return t(.helperReady)
        case .notInstalled: return t(.helperNotInstalled)
        case .needsApproval: return t(.helperNeedsApproval)
        case .unavailable: return t(.helperUnavailable)
        }
    }

    var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    }

    /// Status lines for `Wakey --status`.
    var statusReport: String {
        let lines = [
            "lid closed: \(system.lidClosed)",
            "external display: \(system.externalDisplay)",
            "power: \(system.onBattery ? "battery" : "AC"), battery: \(system.batteryPercent.map { "\($0)%" } ?? "none")",
            "thermal hot: \(system.thermalHot)",
            "helper: \(lid.status)",
            "claude hooks: \(hooksInstalled ? "installed" : "not installed")",
            "AI running: \(AIApp.allCases.filter { ai.running.contains($0) }.map(\.rawValue))",
            "AI working: \(AIApp.allCases.filter { ai.working.contains($0) }.map(\.rawValue))",
            "AI holding sleep: \(AIApp.allCases.filter { ai.holdingSleep.contains($0) }.map(\.rawValue))",
            "decision: idle=\(decision.holdIdle) display=\(decision.holdDisplay) lid=\(decision.lidMode) needsHelper=\(decision.lidNeedsHelper) reason=\(decision.reason.rawValue)",
            "menu: \(heroLine) | \(holdText) | \(reasonText)"
        ]
        return lines.joined(separator: "\n")
    }

    private enum Keys {
        static let language = "language"
        static let appearance = "appearance"
        static let autoEnabled = "autoEnabled"
        static let lidAway = "lidAway"
        static let keepOnBattery = "keepOnBattery"
        static let remoteStandby = "remoteStandby"
        static let clamshellAuto = "clamshellAuto"
        static let thermalGuard = "thermalGuard"
        static let batteryFloor = "batteryFloor"
        static let releaseMinutes = "releaseMinutes"
        static let watchClaude = "watchClaude"
        static let watchChatGPT = "watchChatGPT"
        static let watchAntigravity = "watchAntigravity"
        static let watchTerminal = "watchTerminal"
    }
}

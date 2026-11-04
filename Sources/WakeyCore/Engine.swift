import Foundation

/// Everything the engine needs to decide which sleep stages to block.
public struct EngineInput: Equatable, Sendable {
    // Preferences
    public var autoEnabled = true
    public var remoteStandby = false
    public var keepOnBattery = false
    public var batteryFloor = 20
    public var lidAway = false
    public var clamshellAuto = true
    public var thermalGuard = true

    // Manual toggles under Advanced, and the "step away" hold
    public var manualIdle = false
    public var manualDisplay = false
    public var manualLid = false
    public var awayHold = false

    // Detected state
    public var aiWorking = false
    public var onBattery = false
    public var batteryPercent: Int?
    public var lidClosed = false
    public var externalDisplay = false
    public var thermalHot = false
    public var helperReady = false

    public init() {}
}

/// Why the engine decided what it did; the menu shows this as one sentence.
public enum Reason: String, Equatable, Sendable {
    case autoOff
    case idle
    case pausedOnBattery
    case batteryFloor
    case remoteStandby
    case clamshell
    case lidAway
    case normal
}

public struct Decision: Equatable, Sendable {
    /// Stage 4: block idle sleep (power assertion).
    public var holdIdle = false
    /// Stages 1–2: keep the display on (power assertion).
    public var holdDisplay = false
    /// Stages 5–6: lid mode (`pmset disablesleep 1` through the helper).
    public var lidMode = false
    /// Lid mode is wanted but the helper isn't installed or approved.
    public var lidNeedsHelper = false
    /// Lid mode is wanted but turned off because the Mac is hot.
    public var lidBlockedByHeat = false
    public var reason: Reason = .autoOff

    public var isActive: Bool { holdIdle || holdDisplay || lidMode }

    public init() {}
}

public enum Situation: Equatable, Sendable {
    case lidOpenAC
    case lidOpenBattery
    case clamshell
    case lidClosedNoDisplay

    public init(lidClosed: Bool, externalDisplay: Bool, onBattery: Bool) {
        switch (lidClosed, externalDisplay) {
        case (true, true): self = .clamshell
        case (true, false): self = .lidClosedNoDisplay
        default: self = onBattery ? .lidOpenBattery : .lidOpenAC
        }
    }
}

public enum Engine {
    public static func decide(_ input: EngineInput) -> Decision {
        let belowFloor = input.onBattery && (input.batteryPercent ?? 100) <= input.batteryFloor
        let batteryBlocked = input.onBattery && (!input.keepOnBattery || belowFloor)
        let wanted = input.aiWorking || input.remoteStandby
        let autoActive = input.autoEnabled && wanted && !batteryBlocked
        let clamshell = input.lidClosed && input.externalDisplay

        var decision = Decision()
        decision.holdIdle = !batteryBlocked && (autoActive || input.manualIdle || input.awayHold)
        decision.holdDisplay = !batteryBlocked && input.manualDisplay

        // Lid mode has to be on *before* the lid closes or the monitor goes away:
        // once that happens the Mac is already asleep and Wakey can't react.
        let autoLid = autoActive && ((clamshell && input.clamshellAuto) || input.lidAway)
        let lidWanted = !batteryBlocked && (autoLid || input.manualLid)
        let tooHot = input.thermalGuard && input.thermalHot
        decision.lidMode = lidWanted && input.helperReady && !tooHot
        decision.lidNeedsHelper = lidWanted && !input.helperReady
        decision.lidBlockedByHeat = lidWanted && input.helperReady && tooHot

        if !input.autoEnabled {
            decision.reason = .autoOff
        } else if !wanted {
            decision.reason = .idle
        } else if belowFloor && input.keepOnBattery {
            decision.reason = .batteryFloor
        } else if batteryBlocked {
            decision.reason = .pausedOnBattery
        } else if !input.aiWorking {
            decision.reason = .remoteStandby
        } else if clamshell && input.clamshellAuto {
            decision.reason = .clamshell
        } else if input.lidAway {
            decision.reason = .lidAway
        } else {
            decision.reason = .normal
        }
        return decision
    }
}

import Testing
@testable import WakeyCore

@Suite struct EngineTests {
    private func input(_ configure: (inout EngineInput) -> Void) -> EngineInput {
        var value = EngineInput()
        value.helperReady = true
        configure(&value)
        return value
    }

    @Test func lidOpenOnPowerBlocksIdleSleepOnly() {
        let decision = Engine.decide(input { $0.aiWorking = true })
        #expect(decision.holdIdle)
        #expect(!decision.holdDisplay)
        #expect(!decision.lidMode)
        #expect(decision.reason == .normal)
    }

    @Test func clamshellTurnsOnLidModeAhead() {
        let decision = Engine.decide(input {
            $0.aiWorking = true
            $0.lidClosed = true
            $0.externalDisplay = true
        })
        #expect(decision.holdIdle)
        #expect(decision.lidMode)
        #expect(decision.reason == .clamshell)
    }

    @Test func clamshellAutoCanBeTurnedOff() {
        let decision = Engine.decide(input {
            $0.aiWorking = true
            $0.lidClosed = true
            $0.externalDisplay = true
            $0.clamshellAuto = false
        })
        #expect(decision.holdIdle)
        #expect(!decision.lidMode)
    }

    @Test func nothingHeldWhenNoAIIsWorking() {
        let decision = Engine.decide(input { $0.aiWorking = false })
        #expect(!decision.isActive)
        #expect(decision.reason == .idle)
    }

    @Test func remoteStandbyKeepsMacAwakeBetweenTasks() {
        let decision = Engine.decide(input {
            $0.aiWorking = false
            $0.remoteStandby = true
            $0.lidClosed = true
            $0.externalDisplay = true
        })
        #expect(decision.holdIdle)
        #expect(decision.lidMode)
        #expect(decision.reason == .remoteStandby)
    }

    @Test func batteryPausesUnlessKeepOnBattery() {
        let paused = Engine.decide(input {
            $0.aiWorking = true
            $0.onBattery = true
            $0.batteryPercent = 80
        })
        #expect(!paused.isActive)
        #expect(paused.reason == .pausedOnBattery)

        let kept = Engine.decide(input {
            $0.aiWorking = true
            $0.onBattery = true
            $0.batteryPercent = 80
            $0.keepOnBattery = true
        })
        #expect(kept.holdIdle)
    }

    @Test func batteryFloorReleasesEverythingIncludingManualToggles() {
        let decision = Engine.decide(input {
            $0.aiWorking = true
            $0.onBattery = true
            $0.keepOnBattery = true
            $0.batteryPercent = 20
            $0.manualIdle = true
            $0.manualLid = true
        })
        #expect(!decision.isActive)
        #expect(decision.reason == .batteryFloor)
    }

    @Test func lidAwayArmsLidModeWhileLidIsStillOpen() {
        let decision = Engine.decide(input {
            $0.aiWorking = true
            $0.lidAway = true
        })
        #expect(decision.lidMode)
        #expect(decision.reason == .lidAway)
    }

    @Test func lidModeNeedsHelper() {
        let decision = Engine.decide(input {
            $0.aiWorking = true
            $0.lidAway = true
            $0.helperReady = false
        })
        #expect(!decision.lidMode)
        #expect(decision.lidNeedsHelper)
        #expect(decision.holdIdle)
    }

    @Test func heatTurnsLidModeOff() {
        let decision = Engine.decide(input {
            $0.manualLid = true
            $0.thermalHot = true
        })
        #expect(!decision.lidMode)
        #expect(decision.lidBlockedByHeat)

        let noGuard = Engine.decide(input {
            $0.manualLid = true
            $0.thermalHot = true
            $0.thermalGuard = false
        })
        #expect(noGuard.lidMode)
    }

    @Test func manualTogglesWorkWithAutoOff() {
        let decision = Engine.decide(input {
            $0.autoEnabled = false
            $0.aiWorking = true
            $0.manualDisplay = true
        })
        #expect(!decision.holdIdle)
        #expect(decision.holdDisplay)
        #expect(decision.reason == .autoOff)
    }

    @Test func stepAwayHoldsIdleSleep() {
        let decision = Engine.decide(input {
            $0.autoEnabled = false
            $0.awayHold = true
        })
        #expect(decision.holdIdle)
    }

    @Test func situationMapping() {
        #expect(Situation(lidClosed: true, externalDisplay: true, onBattery: false) == .clamshell)
        #expect(Situation(lidClosed: true, externalDisplay: false, onBattery: true) == .lidClosedNoDisplay)
        #expect(Situation(lidClosed: false, externalDisplay: true, onBattery: true) == .lidOpenBattery)
        #expect(Situation(lidClosed: false, externalDisplay: false, onBattery: false) == .lidOpenAC)
    }
}

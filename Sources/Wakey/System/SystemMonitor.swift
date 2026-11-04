import AppKit
import CoreGraphics
import IOKit
import IOKit.ps

/// What Wakey knows about the Mac's lid, displays, power and temperature.
struct SystemState: Equatable {
    var lidClosed = false
    var externalDisplay = false
    var hasBattery = false
    var onBattery = false
    var batteryPercent: Int?
    var thermalHot = false
}

enum SystemProbe {
    static func read() -> SystemState {
        var state = SystemState()
        state.lidClosed = lidClosed()
        state.externalDisplay = hasExternalDisplay()
        readPower(into: &state)
        state.thermalHot = ProcessInfo.processInfo.thermalState.rawValue >= ProcessInfo.ThermalState.serious.rawValue
        return state
    }

    /// `AppleClamshellState` on IOPMrootDomain. Desktops without a lid report false.
    static func lidClosed() -> Bool {
        let rootDomain = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("IOPMrootDomain"))
        guard rootDomain != 0 else { return false }
        defer { IOObjectRelease(rootDomain) }
        let value = IORegistryEntryCreateCFProperty(rootDomain, "AppleClamshellState" as CFString, kCFAllocatorDefault, 0)?
            .takeRetainedValue()
        return (value as? Bool) ?? false
    }

    /// Any online display that isn't the built-in panel, including sleeping ones.
    static func hasExternalDisplay() -> Bool {
        var count: UInt32 = 0
        guard CGGetOnlineDisplayList(0, nil, &count) == .success, count > 0 else { return false }
        var displays = [CGDirectDisplayID](repeating: 0, count: Int(count))
        guard CGGetOnlineDisplayList(count, &displays, &count) == .success else { return false }
        return displays.prefix(Int(count)).contains { CGDisplayIsBuiltin($0) == 0 }
    }

    static func readPower(into state: inout SystemState) {
        guard let info = IOPSCopyPowerSourcesInfo()?.takeRetainedValue() else { return }
        let providing = IOPSGetProvidingPowerSourceType(info)?.takeUnretainedValue() as String?
        state.onBattery = providing == kIOPMBatteryPowerKey
        guard let list = IOPSCopyPowerSourcesList(info)?.takeRetainedValue() as? [CFTypeRef] else { return }
        for source in list {
            guard let description = IOPSGetPowerSourceDescription(info, source)?.takeUnretainedValue() as? [String: Any],
                  (description[kIOPSTypeKey] as? String) == kIOPSInternalBatteryType else { continue }
            state.hasBattery = true
            if let current = description[kIOPSCurrentCapacityKey] as? Int,
               let max = description[kIOPSMaxCapacityKey] as? Int, max > 0 {
                state.batteryPercent = Int((Double(current) / Double(max) * 100).rounded())
            }
        }
    }
}

/// Calls `onChange` when anything in `SystemState` may have changed.
/// The lid has no public notification, so it is also polled.
final class SystemMonitor {
    private var observers: [NSObjectProtocol] = []
    private var powerSource: CFRunLoopSource?
    private let onChange: () -> Void

    init(onChange: @escaping () -> Void) {
        self.onChange = onChange
    }

    func start() {
        let center = NotificationCenter.default
        let workspace = NSWorkspace.shared.notificationCenter
        observers.append(center.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in self?.onChange() })
        observers.append(center.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { [weak self] _ in self?.onChange() })
        observers.append(center.addObserver(forName: .wakeyPowerSourceChanged, object: nil, queue: .main) { [weak self] _ in self?.onChange() })
        observers.append(workspace.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in self?.onChange() })

        if let source = IOPSNotificationCreateRunLoopSource({ _ in
            NotificationCenter.default.post(name: .wakeyPowerSourceChanged, object: nil)
        }, nil)?.takeRetainedValue() {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            powerSource = source
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
        if let powerSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), powerSource, .defaultMode) }
    }
}

extension Notification.Name {
    static let wakeyPowerSourceChanged = Notification.Name("WakeyPowerSourceChanged")
}

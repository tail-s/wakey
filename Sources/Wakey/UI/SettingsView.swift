import AppKit
import Combine
import SwiftUI
import WakeyCore

enum SettingsTab: Hashable {
    case general, detection, about
}

/// The Settings window (design F).
struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @State private var tab: SettingsTab

    init(initialTab: SettingsTab = .general) {
        _tab = State(initialValue: initialTab)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker(model.t(.settingsTitle), selection: $tab) {
                Text(model.t(.tabGeneral)).tag(SettingsTab.general)
                Text(model.t(.tabDetection)).tag(SettingsTab.detection)
                Text(model.t(.tabAbout)).tag(SettingsTab.about)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 320)
            .padding(.vertical, 12)
            Divider()
            switch tab {
            case .general: GeneralSettings()
            case .detection: DetectionSettings()
            case .about: AboutSettings()
            }
        }
        .frame(width: 540, height: 640, alignment: .top)
        .tint(Brand.accent)
        .environment(\.locale, Locale(identifier: model.language.rawValue))
    }
}

private struct GeneralSettings: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section(model.t(.sectionLanguage)) {
                Picker(model.t(.language), selection: $model.language) {
                    ForEach(AppLanguage.allCases) { Text($0.nativeName).tag($0) }
                }
                VStack(alignment: .leading, spacing: 6) {
                    Picker(model.t(.appearance), selection: $model.appearance) {
                        Text(model.t(.appearanceSystem)).tag(AppearanceMode.system)
                        Text(model.t(.appearanceLight)).tag(AppearanceMode.light)
                        Text(model.t(.appearanceDark)).tag(AppearanceMode.dark)
                    }
                    .pickerStyle(.segmented)
                    Caption(model.t(.appearanceNote))
                }
            }

            Section(model.t(.sectionBehavior)) {
                Toggle(model.t(.launchAtLogin), isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                if model.launchAtLoginFailed {
                    Caption(model.t(.launchAtLoginFailed), color: .red)
                }
                Toggle(isOn: $model.remoteStandby) {
                    TitleAndCaption(title: model.t(.remoteStandbySettings), caption: model.t(.remoteStandbySubtitle))
                }
                Picker(model.t(.releaseAfter), selection: $model.releaseMinutes) {
                    ForEach([1, 5, 10], id: \.self) { Text(model.f(.minutesFormat, $0)).tag($0) }
                }
                Picker(model.t(.batteryFloor), selection: $model.batteryFloor) {
                    ForEach([10, 20, 30], id: \.self) { Text("\($0)%").tag($0) }
                }
            }

            Section(model.t(.sectionLid)) {
                LabeledContent {
                    HStack(spacing: 8) {
                        StatusBadge(text: model.helperStatusText, good: model.lid.status == .ready)
                        helperButton
                    }
                } label: {
                    TitleAndCaption(title: model.t(.helper), caption: model.t(.helperSubtitle))
                }
                if let error = model.lid.lastError {
                    Caption(error, color: .red)
                }
                Toggle(isOn: $model.clamshellAuto) {
                    TitleAndCaption(title: model.t(.clamshellAuto), caption: model.t(.clamshellAutoSubtitle))
                }
                Toggle(model.t(.thermalGuard), isOn: $model.thermalGuard)
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder private var helperButton: some View {
        switch model.lid.status {
        case .ready:
            Button(model.t(.helperUninstall)) { model.lid.uninstall() }
        case .notInstalled:
            Button(model.t(.helperInstall)) { model.lid.install() }
        case .needsApproval:
            Button(model.t(.helperOpenLoginItems)) { model.lid.openLoginItems() }
        case .unavailable:
            EmptyView()
        }
    }
}

private struct DetectionSettings: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        Form {
            Section(model.t(.sectionApps)) {
                ForEach(AIApp.allCases) { app in
                    Toggle(isOn: Binding(get: { model.watch[app] }, set: { model.watch[app] = $0 })) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(title(of: app))
                                StatusBadge(text: model.statusText(for: app), good: model.ai.working.contains(app))
                            }
                            Caption(signal(of: app))
                        }
                    }
                }
            }

            Section {
                LabeledContent {
                    HStack(spacing: 8) {
                        if model.hooksInstalled {
                            StatusBadge(text: model.t(.claudeHooksOn), good: true)
                            Button(model.t(.claudeHooksRemove)) { model.removeHooks() }
                        } else {
                            Button(model.t(.claudeHooksAdd)) { model.installHooks() }
                        }
                    }
                } label: {
                    TitleAndCaption(title: model.t(.claudeHooks), caption: model.t(.claudeHooksSubtitle))
                }
                if let error = model.hooksError {
                    Caption(error, color: .red)
                }
            }

            Section {
                Caption(model.t(.detectionNote))
            }
        }
        .formStyle(.grouped)
    }

    private func title(of app: AIApp) -> String {
        switch app {
        case .claude: return model.t(.appClaude)
        case .chatGPT: return model.t(.appChatGPT)
        case .antigravity: return model.t(.appAntigravity)
        case .terminal: return model.t(.appTerminal)
        }
    }

    private func signal(of app: AIApp) -> String {
        switch app {
        case .claude: return model.t(.signalClaude)
        case .chatGPT: return model.t(.signalChatGPT)
        case .antigravity: return model.t(.signalAntigravity)
        case .terminal: return model.t(.signalTerminal)
        }
    }
}

private struct AboutSettings: View {
    @EnvironmentObject private var model: AppModel

    var body: some View {
        VStack(spacing: 12) {
            AppIconView(size: 80)
            Text("Wakey")
                .font(.system(size: 20, weight: .bold))
            Text(model.f(.versionFormat, model.version))
                .foregroundStyle(.secondary)
            GroupBox {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach([L10nKey.whatsNew1, .whatsNew2, .whatsNew3], id: \.self) { key in
                        Label(model.t(key), systemImage: "checkmark")
                            .font(.system(size: 12))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(4)
            } label: {
                Text(model.t(.whatsNew)).font(.system(size: 12, weight: .semibold))
            }
            .frame(maxWidth: 380)
            HStack {
                Button(model.t(.openChangelog)) { model.openBundledDocument("CHANGELOG") }
                Button(model.t(.openReadme)) { model.openBundledDocument(readmeName) }
            }
            Spacer()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }

    private var readmeName: String {
        switch model.language {
        case .english: return "README"
        case .korean: return "README.ko"
        case .japanese: return "README.ja"
        }
    }
}

// MARK: - Shared pieces

private struct Caption: View {
    var text: String
    var color: Color = .secondary

    init(_ text: String, color: Color = .secondary) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .font(.system(size: 11))
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

private struct TitleAndCaption: View {
    var title: String
    var caption: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Caption(caption)
        }
    }
}

struct StatusBadge: View {
    var text: String
    var good: Bool

    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 1)
            .foregroundStyle(good ? Color.green : Color.secondary)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill((good ? Color.green : Color.secondary).opacity(0.15))
            )
    }
}

/// Opens the Settings window. Managed with AppKit so it never opens by itself at launch.
@MainActor
final class SettingsWindowController {
    static let shared = SettingsWindowController()

    private var window: NSWindow?
    private var titleUpdates: AnyCancellable?

    func show(model: AppModel) {
        if window == nil {
            let host = NSHostingController(rootView: SettingsView().environmentObject(model))
            let window = NSWindow(contentViewController: host)
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.isReleasedWhenClosed = false
            window.center()
            titleUpdates = model.$language.sink { [weak window] language in
                window?.title = L10n.string(.settingsTitle, language)
            }
            self.window = window
        }
        NSApp.activate(ignoringOtherApps: true)
        window?.makeKeyAndOrderFront(nil)
    }
}

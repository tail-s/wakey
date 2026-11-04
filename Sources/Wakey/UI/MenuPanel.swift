import AppKit
import SwiftUI
import WakeyCore

/// The panel that opens from the menu bar icon (design E).
struct MenuPanel: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var showAdvanced: Bool

    init(showAdvanced: Bool = false) {
        _showAdvanced = State(initialValue: showAdvanced)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            hero
            lidCard
            timerSection
            stepAwayButton
            Divider()
            statusSection
            optionToggles
            Divider()
            advancedSection
            Divider()
            footer
        }
        .padding(12)
        .frame(width: 340)
        .tint(Brand.accent)
        .environment(\.locale, Locale(identifier: model.language.rawValue))
    }

    private func t(_ key: L10nKey) -> String { model.t(key) }

    // MARK: Hero: the one switch

    private var hero: some View {
        let on = model.autoEnabled
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                AppIconView(size: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t(.title))
                        .font(.system(size: 14, weight: .semibold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text(model.heroLine)
                        .font(.system(size: 11.5))
                        .opacity(0.9)
                }
                Spacer(minLength: 8)
                Toggle(t(.title), isOn: $model.autoEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .tint(on ? Brand.lavender : Brand.accent)
            }
            Rectangle()
                .fill(on ? Color.white.opacity(0.25) : Color.primary.opacity(0.1))
                .frame(height: 1)
            VStack(alignment: .leading, spacing: 3) {
                Text("\(t(.activeNow)) \(model.holdText)")
                    .font(.system(size: 12, weight: .semibold))
                Text(model.reasonText)
                    .font(.system(size: 11.5))
                    .opacity(0.9)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .foregroundStyle(on ? Color.white : Color.primary)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(on ? Brand.hero(colorScheme) : Color(nsColor: .controlBackgroundColor))
        )
    }

    // MARK: Lid

    private var lidCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(t(.lidSection))
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Text(model.situationText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .overlay(Capsule().stroke(Color.secondary.opacity(0.4)))
            }
            SwitchRow(title: t(.lidAwayTitle), subtitle: t(.lidAwaySubtitle), isOn: $model.lidAway)
            if let note = model.lidNote {
                Label(note, systemImage: "exclamationmark.triangle")
                    .font(.system(size: 11))
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(cardBackground)
    }

    // MARK: Timer and step away

    private var timerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(t(.timer)) · \(model.timerText)")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(TimerChoice.allCases) { choice in
                    Button(t(choice.labelKey)) { model.timer = choice }
                        .buttonStyle(ChipButtonStyle(selected: model.timer == choice))
                        .accessibilityAddTraits(model.timer == choice ? .isSelected : [])
                }
            }
        }
        .padding(.horizontal, 4)
    }

    private var stepAwayButton: some View {
        Button {
            model.stepAway()
        } label: {
            Label(t(.stepAway), systemImage: "lock.display")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .padding(.horizontal, 4)
    }

    // MARK: Status

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            StatusLine(symbol: model.system.onBattery ? "battery.75" : "powerplug", text: model.powerText)
            StatusLine(symbol: "display", text: model.lidText)
            StatusLine(symbol: "sparkles", text: model.detectedText)
            StatusLine(symbol: "moon.zzz", text: model.blockingText)
        }
        .padding(.horizontal, 6)
    }

    private var optionToggles: some View {
        VStack(alignment: .leading, spacing: 6) {
            Toggle(model.f(.keepOnBatteryFormat, model.batteryFloor), isOn: $model.keepOnBattery)
            Toggle(t(.remoteStandby), isOn: $model.remoteStandby)
        }
        .toggleStyle(.checkbox)
        .font(.system(size: 12))
        .padding(.horizontal, 6)
    }

    // MARK: Advanced

    private var advancedSection: some View {
        DisclosureGroup(isExpanded: $showAdvanced) {
            VStack(alignment: .leading, spacing: 8) {
                Text(t(.advancedNote))
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                SwitchRow(title: t(.manualIdle), subtitle: t(.manualIdleSubtitle), isOn: $model.manualIdle)
                SwitchRow(title: t(.manualDisplay), subtitle: t(.manualDisplaySubtitle), isOn: $model.manualDisplay)
                SwitchRow(title: t(.manualLid), subtitle: t(.manualLidSubtitle), isOn: $model.manualLid)
            }
            .padding(.top, 6)
        } label: {
            Text(t(.advanced))
                .font(.system(size: 13, weight: .medium))
        }
        .padding(.horizontal, 6)
    }

    // MARK: Footer

    private var footer: some View {
        VStack(spacing: 0) {
            MenuRow(title: t(.openSettings), shortcut: "⌘,") { model.openSettings() }
                .keyboardShortcut(",", modifiers: .command)
            MenuRow(title: t(.quit), shortcut: "⌘Q") { NSApp.terminate(nil) }
                .keyboardShortcut("q", modifiers: .command)
        }
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(Color(nsColor: .controlBackgroundColor))
    }
}

// MARK: - Small building blocks

struct SwitchRow: View {
    var title: String
    var subtitle: String?
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            Toggle(title, isOn: $isOn)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }
}

struct StatusLine: View {
    var symbol: String
    var text: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .frame(width: 16)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(text)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(.system(size: 12))
    }
}

struct ChipButtonStyle: ButtonStyle {
    var selected: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .frame(maxWidth: .infinity, minHeight: 28)
            .foregroundStyle(selected ? Color.white : Color.primary)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(selected ? Brand.accent : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .stroke(selected ? Brand.accent : Color.secondary.opacity(0.35))
            )
            .opacity(configuration.isPressed ? 0.75 : 1)
            .contentShape(Rectangle())
    }
}

/// A full-width row that highlights on hover, like a menu item.
struct MenuRow: View {
    var title: String
    var shortcut: String
    var action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                Spacer()
                Text(shortcut).foregroundStyle(.secondary)
            }
            .font(.system(size: 13))
            .padding(.horizontal, 8)
            .frame(height: 28)
            .contentShape(Rectangle())
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(hovering ? Color.primary.opacity(0.08) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

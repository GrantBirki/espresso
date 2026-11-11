import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: SettingsWindowState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Espresso")
                        .font(.largeTitle.weight(.semibold))
                        .accessibilityAddTraits(.isHeader)
                    Label(state.menuState.statusTitle, systemImage: state.menuState.statusSymbolName)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { settings.autoLaunchEnabled },
                        set: { settings.setAutoLaunchEnabled($0) }
                    )) {
                        Text("Launch at login")
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .toggleStyle(.switch)

                    if let message = settings.launchAtLoginMessage {
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background { GlassPanelBackground() }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Power behavior")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                    Text(
                        "Espresso keeps the display awake, which also prevents idle system sleep. "
                            + "Manual sleep, lid close, low battery, and thermal events can still sleep the Mac."
                    )
                    .font(.callout)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(24)
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing, spacing: 0) {
            Text("Version \(BuildInfo.version) (\(BuildInfo.gitSHA))")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .frame(width: 560, height: 360)
    }
}

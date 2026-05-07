import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var state: SettingsWindowState

    var body: some View {
        GlassEffectContainer(spacing: 18) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 14) {
                    Image(systemName: state.menuState.statusSymbolName)
                        .font(.system(size: 34, weight: .semibold))
                        .frame(width: 60, height: 60)
                        .glassEffect(.regular.interactive(false), in: .rect(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Espresso")
                            .font(.title2.bold())
                        Text(state.menuState.statusTitle)
                            .foregroundStyle(.secondary)
                    }
                }

                GlassPanel {
                    Toggle("Launch at login", isOn: $settings.autoLaunchEnabled)
                        .toggleStyle(.switch)
                }

                GlassPanel(prominence: .subtle) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Power behavior")
                            .font(.headline)
                        Text(
                            "Espresso keeps the display awake, which also prevents idle system sleep. "
                                + "Manual sleep, lid close, low battery, and thermal events can still sleep the Mac."
                        )
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Spacer()

                Text("Version \(BuildInfo.version) (\(BuildInfo.gitSHA))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(24)
            .frame(width: 560, height: 360)
        }
    }
}

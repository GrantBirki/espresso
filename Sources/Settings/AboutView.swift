import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        GlassEffectContainer(spacing: 18) {
            VStack(spacing: 18) {
                Image(nsImage: NSImage(named: NSImage.applicationIconName) ?? NSImage())
                    .resizable()
                    .frame(width: 96, height: 96)
                    .glassEffect(.regular.interactive(false), in: .rect(cornerRadius: 24))

                VStack(spacing: 6) {
                    Text("Espresso")
                        .font(.title.bold())
                    Text("Menu bar app that keeps your Mac awake")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                GlassPanel(prominence: .subtle) {
                    VStack(spacing: 4) {
                        Text("Version \(BuildInfo.version)")
                        Text("Git \(BuildInfo.gitSHA)")
                            .foregroundStyle(.secondary)
                    }
                    .font(.callout)
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(24)
            .frame(width: 420, height: 300)
        }
    }
}

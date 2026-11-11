import AppKit
import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 16) {
            if let icon = NSImage(named: NSImage.applicationIconName) {
                Image(nsImage: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 112, height: 112)
                    .accessibilityHidden(true)
            }

            VStack(spacing: 5) {
                Text("Espresso")
                    .font(.largeTitle.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                Text("Menu bar app that keeps your Mac awake")
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 3) {
                Text("Version \(BuildInfo.version)")
                Text("Git \(BuildInfo.gitSHA)")
                    .foregroundStyle(.secondary)
            }
            .font(.callout)
            .textSelection(.enabled)
        }
        .multilineTextAlignment(.center)
        .padding(24)
        .frame(width: 420, height: 300)
    }
}

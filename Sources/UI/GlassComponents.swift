import SwiftUI

struct GlassPanelBackground: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 16)
        if reduceTransparency {
            shape
                .fill(Color(nsColor: .controlBackgroundColor))
                .strokeBorder(.separator)
        } else {
            Color.clear.glassEffect(.regular, in: shape)
        }
    }
}

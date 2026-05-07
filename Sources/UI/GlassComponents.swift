import SwiftUI

enum GlassProminence {
    case subtle
    case balanced
    case prominent
}

struct GlassPanel<Content: View>: View {
    var prominence: GlassProminence = .balanced
    @ViewBuilder var content: Content
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        Group {
            if reduceTransparency {
                content
                    .padding(16)
                    .background(.regularMaterial, in: shape)
                    .overlay(shape.stroke(.white.opacity(0.18), lineWidth: 1))
            } else {
                content
                    .padding(16)
                    .glassEffect(glass, in: shape)
            }
        }
    }

    private var cornerRadius: CGFloat {
        switch prominence {
        case .subtle:
            16
        case .balanced:
            20
        case .prominent:
            24
        }
    }

    private var glass: Glass {
        switch prominence {
        case .subtle:
            .regular.interactive(false)
        case .balanced:
            .regular.interactive(false)
        case .prominent:
            .regular.tint(.brown.opacity(0.16)).interactive(false)
        }
    }
}

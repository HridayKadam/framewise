import SwiftUI

#if os(iOS)
import ARKit
import RealityKit
#endif

struct RootView: View {
    @EnvironmentObject var coordinator: AppCoordinator

    var body: some View {
        ZStack {
            // AR Background
            #if os(iOS)
            ARViewContainer(arEngine: coordinator.ar)
                .edgesIgnoringSafeArea(.all)
            #else
            Color.black.edgesIgnoringSafeArea(.all)
            Text("AR Preview Only Available on iOS")
                .foregroundColor(.white)
            #endif

            // UI Overlay
            VStack {
                HStack {
                    ScoreBadge(score: coordinator.score)
                    Spacer()
                }
                .padding()

                Spacer()

                if coordinator.ar.isTrackingLimited {
                    Text("Tracking Limited - Move Device")
                        .font(DSTypography.caption)
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(8)
                        .padding(.bottom, DSSpacing.xl)
                }
            }
        }
    }
}

#if os(iOS)
struct ARViewContainer: UIViewRepresentable {
    let arEngine: AROverlayEngine

    func makeUIView(context: Context) -> ARView {
        return arEngine.makeARView()
    }

    func updateUIView(_ uiView: ARView, context: Context) {}
}
#endif

struct ScoreBadge: View {
    let score: CompositionScore

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("COMPOSITION")
                .font(DSTypography.caption)
                .foregroundColor(DSColor.secondaryText)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(score.total)")
                    .font(DSTypography.title)
                    .foregroundColor(colorForTier(score.tier))
                Text("/100")
                    .font(DSTypography.headline)
                    .foregroundColor(DSColor.secondaryText)
            }
            
            Text(score.tier.rawValue.uppercased())
                .font(DSTypography.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(colorForTier(score.tier).opacity(0.2))
                .foregroundColor(colorForTier(score.tier))
                .cornerRadius(4)
        }
        .padding()
        .background(Color.black.opacity(0.4))
        .cornerRadius(12)
    }

    private func colorForTier(_ tier: CompositionScore.Tier) -> Color {
        switch tier {
        case .excellent: return DSColor.success
        case .good: return .blue
        case .fair: return DSColor.warning
        case .poor: return DSColor.danger
        }
    }
}

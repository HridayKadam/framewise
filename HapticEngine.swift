import Foundation
import CoreHaptics
import Combine

final class HapticEngine {
    private var engine: CHHapticEngine?
    private var lastTier: CompositionScore.Tier?

    init() {
        prepare()
    }

    private func prepare() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            engine = nil
        }
    }

    func playScoreFeedback(score: Int, tier: CompositionScore.Tier) {
        // Trigger only on tier transitions.
        guard lastTier != tier else { return }
        lastTier = tier

        let intensity = Float(min(max(Double(score) / 100.0, 0.0), 1.0))
        let sharpness = intensity

        let event = CHHapticEvent(eventType: .hapticTransient,
                                  parameters: [
                                    CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                                    CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                                  ],
                                  relativeTime: 0)
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            // Ignore haptic errors to avoid disrupting UX.
        }
    }
}

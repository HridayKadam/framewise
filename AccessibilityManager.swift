import Foundation
import AVFoundation
import Combine

enum AccessibilityMode: String, CaseIterable, Identifiable {
    case standard
    case voiceGuided
    case hapticOnly
    case largeOverlay
    case highContrast

    var id: String { rawValue }
}

final class AccessibilityManager: ObservableObject {
    @Published var mode: AccessibilityMode = .standard

    private let speech = AVSpeechSynthesizer()
    private var lastUtterTime: Date = .distantPast

    func speak(_ text: String, tier: CompositionScore.Tier) {
        guard mode == .voiceGuided else { return }
        let now = Date()
        guard now.timeIntervalSince(lastUtterTime) > 1.5 else { return } // throttle 1.5s
        lastUtterTime = now
        let utterance = AVSpeechUtterance(string: text)
        if tier == .excellent { utterance.pitchMultiplier = 1.1 }
        speech.speak(utterance)
    }
}

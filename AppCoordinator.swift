import Foundation
import Combine
import AVFoundation

final class AppCoordinator: ObservableObject {
    // Engines
    let camera = CameraEngine()
    let vision = VisionProcessor()
    let extractor = FeatureExtractor()
    let scorer = CompositionScorer()
    let ar = AROverlayEngine()
    let motion = MotionManager.shared
    let haptics = HapticEngine()
    let accessibility = AccessibilityManager()

    // State publishers for UI
    @Published var score: CompositionScore = CompositionScore(total: 0, ruleOfThirds: 0, subjectWeight: 0, horizonLevel: 0, leadRoom: 0, confidence: 0.6, tier: .poor)

    private var cancellables = Set<AnyCancellable>()

    func start() {
        motion.start()
        camera.start()
        ar.start()

        // Camera -> Vision
        camera.sampleBufferPublisher
            .receive(on: vision.visionQueue)
            .handleEvents(receiveOutput: { [weak self] buffer in self?.vision.process(sampleBuffer: buffer) })
            .sink { _ in }
            .store(in: &cancellables)

        // Vision -> FeatureExtractor
        vision.resultPublisher
            .combineLatest(motion.horizonAnglePublisher)
            .map { vision, roll in
                self.extractor.extract(from: vision, horizonAngle: roll)
                return ()
            }
            .sink { _ in }
            .store(in: &cancellables)

        // Features -> Scorer (back-pressure .max(1))
        extractor.publisher
            .receive(on: scorer.mlQueue)
            .buffer(size: 1, prefetch: .keepFull, whenFull: .dropOldest)
            .sink { [weak self] features in
                self?.scorer.score(features: features)
            }
            .store(in: &cancellables)

        // Scorer -> UI + AR + Haptics + Accessibility
        scorer.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in
                guard let self else { return }
                self.score = score
                self.ar.updateOpacity(for: score.tier)
                self.haptics.playScoreFeedback(score: score.total, tier: score.tier)
                self.accessibility.speak("Score: \(score.total)", tier: score.tier)
            }
            .store(in: &cancellables)
    }

    func stop() {
        camera.stop()
        motion.stop()
        ar.stop()
        cancellables.removeAll()
    }
}

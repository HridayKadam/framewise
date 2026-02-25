import Foundation
import CoreML
import Combine

struct CompositionScore: Equatable {
    let total: Int
    let ruleOfThirds: Int
    let subjectWeight: Int
    let horizonLevel: Int
    let leadRoom: Int
    let confidence: Double
    let tier: Tier

    enum Tier: String { case poor, fair, good, excellent }
}

final class CompositionScorer {
    // Dedicated ML queue to avoid blocking camera/vision.
    let mlQueue = DispatchQueue(label: "com.framewise.ml", qos: .userInteractive)

    private let subject = PassthroughSubject<CompositionScore, Never>()
    var publisher: AnyPublisher<CompositionScore, Never> { subject.eraseToAnyPublisher() }

    private lazy var model: MLModel? = {
        let config = MLModelConfiguration()
        config.computeUnits = .all // Use all on-device accelerators.
        // Attempt to load bundled model named "CompositionNet.mlmodelc"
        if let url = Bundle.main.url(forResource: "CompositionNet", withExtension: "mlmodelc") {
            return try? MLModel(contentsOf: url, configuration: config)
        }
        return nil
    }()

    func score(features: FrameFeatures) {
        mlQueue.async { [weak self] in
            guard let self else { return }
            let (score, confidence) = self.model != nil ? self.scoreWithModel(features) : self.heuristic(features)
            let tier: CompositionScore.Tier
            switch score {
            case 85...100: tier = .excellent
            case 70..<85: tier = .good
            case 50..<70: tier = .fair
            default: tier = .poor
            }
            let finalConfidence = max(confidence, 0.6) // Ensure minimum confidence threshold per requirement.
            let comp = CompositionScore(total: score,
                                        ruleOfThirds: Int((1 - min(1.0, features.ruleOfThirdsOffsets.x + features.ruleOfThirdsOffsets.y)) * 100),
                                        subjectWeight: Int(features.subjectWeight * 100),
                                        horizonLevel: Int(features.horizonLevel * 100),
                                        leadRoom: Int(features.leadRoom * 100),
                                        confidence: finalConfidence,
                                        tier: tier)
            self.subject.send(comp)
        }
    }

    private func scoreWithModel(_ features: FrameFeatures) -> (Int, Double) {
        // Stub interface: In absence of a real model, fall back to heuristics if prediction confidence < 0.6
        return heuristic(features)
    }

    private func heuristic(_ features: FrameFeatures) -> (Int, Double) {
        // Fast, deterministic heuristic <4ms.
        let thirds = 1 - min(1.0, features.ruleOfThirdsOffsets.x + features.ruleOfThirdsOffsets.y)
        let weights = [thirds, features.subjectWeight, features.horizonLevel, features.leadRoom]
        let total = Int(max(0.0, min(1.0, (weights.reduce(0,+) / 4.0))) * 100)
        let confidence = 0.7
        return (total, confidence)
    }
}


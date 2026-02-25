import Foundation
import Vision
import CoreImage
import Combine

struct FrameFeatures {
    let ruleOfThirdsOffsets: (x: Double, y: Double)
    let subjectWeight: Double
    let horizonLevel: Double
    let leadRoom: Double
}

final class FeatureExtractor {
    private let subject = PassthroughSubject<FrameFeatures, Never>()
    var publisher: AnyPublisher<FrameFeatures, Never> { subject.eraseToAnyPublisher() }

    func extract(from vision: VisionResult, horizonAngle: Double) {
        // Heuristics based on face/pose centers and saliency map.
        let subjectWeight: Double
        if !vision.faces.isEmpty { subjectWeight = 0.8 }
        else if !vision.poses.isEmpty { subjectWeight = 0.7 }
        else if vision.saliency != nil { subjectWeight = 0.5 }
        else { subjectWeight = 0.2 }

        // Approximate subject centroid using faces or poses if available.
        var cx: Double = 0.5
        var cy: Double = 0.5
        if let f = vision.faces.first {
            cx = Double(f.boundingBox.midX)
            cy = Double(1 - f.boundingBox.midY)
        } else if let p = vision.poses.first, let torso = try? p.recognizedPoint(.torso) {
            cx = Double(torso.location.x)
            cy = Double(1 - torso.location.y)
        }

        // Distances to nearest rule-of-thirds intersections (1/3, 2/3).
        let thirds: [Double] = [1/3, 2/3]
        let dx = thirds.map { abs(cx - $0) }.min() ?? 0.0
        let dy = thirds.map { abs(cy - $0) }.min() ?? 0.0

        // Lead room heuristic: bias towards right if subject on left and vice versa.
        let leadRoom = cx < 0.5 ? (1 - cx) : cx

        // Horizon level from device roll (radians -> degrees absolute deviation from 0).
        let horizonLevel = max(0.0, 1.0 - min(1.0, abs(horizonAngle) / (.pi / 6))) // within +/-30deg is good

        subject.send(FrameFeatures(ruleOfThirdsOffsets: (dx, dy), subjectWeight: subjectWeight, horizonLevel: horizonLevel, leadRoom: leadRoom))
    }
}

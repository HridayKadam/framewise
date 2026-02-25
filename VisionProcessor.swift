import Foundation
import Vision
import CoreImage
import Combine
import AVFoundation

struct VisionResult {
    let faces: [VNFaceObservation]
    let poses: [VNHumanBodyPoseObservation]
    let saliency: VNSaliencyImageObservation?
}

final class VisionProcessor {
    // Dedicated vision queue. We gate frames to 30fps by processing every 2nd frame.
    let visionQueue = DispatchQueue(label: "com.framewise.vision", qos: .userInteractive)

    private let requestHandler = VNSequenceRequestHandler()

    private let resultSubject = PassthroughSubject<VisionResult, Never>()
    var resultPublisher: AnyPublisher<VisionResult, Never> { resultSubject.eraseToAnyPublisher() }

    private var frameCounter = 0

    func process(sampleBuffer: CMSampleBuffer) {
        frameCounter &+= 1
        // Gate to ~30fps: process every 2nd frame.
        guard frameCounter % 2 == 0 else { return }

        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let requests: [VNRequest] = [
            VNDetectFaceRectanglesRequest(),
            VNDetectHumanBodyPoseRequest(),
            VNGenerateAttentionBasedSaliencyImageRequest()
        ]

        let handler = requestHandler
        let orientation = CGImagePropertyOrientation.right // iOS camera portrait

        visionQueue.async { [weak self] in
            guard let self else { return }
            do {
                try handler.perform(requests, on: pixelBuffer, orientation: orientation)
                let faces = (requests[0].results as? [VNFaceObservation]) ?? []
                let poses = (requests[1].results as? [VNHumanBodyPoseObservation]) ?? []
                let saliency = (requests[2].results as? [VNSaliencyImageObservation])?.first
                let result = VisionResult(faces: faces, poses: poses, saliency: saliency)
                self.resultSubject.send(result)
            } catch {
                // Swallow errors; publish nothing to keep pipeline healthy.
            }
        }
    }
}

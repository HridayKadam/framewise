import Foundation
import AVFoundation
import Combine

final class CameraEngine: NSObject {
    // Dedicated camera queue to ensure capture never blocks UI.
    let cameraQueue = DispatchQueue(label: "com.framewise.camera", qos: .userInteractive)

    private let session = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let sessionQueue = DispatchQueue(label: "com.framewise.camera.session", qos: .userInitiated)

    // Publishes raw CMSampleBuffer frames. Back-pressure is applied downstream with .max(1).
    let sampleBufferPublisher = PassthroughSubject<CMSampleBuffer, Never>()

    private var isConfigured = false

    override init() {
        super.init()
    }

    func start() {
        sessionQueue.async { [weak self] in
            guard let self else { return }
            if !self.isConfigured {
                self.configureSession()
            }
            if !self.session.isRunning {
                self.session.startRunning()
            }
        }
    }

    func stop() {
        sessionQueue.async { [weak self] in
            self?.session.stopRunning()
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .high

        // Prefer back wide camera.
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            session.commitConfiguration()
            return
        }

        do {
            try device.lockForConfiguration()
            // Lock to 60 fps as requested for best temporal resolution.
            if let format = device.activeFormat.videoSupportedFrameRateRanges.first(where: { $0.maxFrameRate >= 60 }) {
                device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
                device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
            }
            device.unlockForConfiguration()
        } catch {
            // If locking fails, continue with defaults; app must not crash.
        }

        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) { session.addInput(input) }
        } catch {
            session.commitConfiguration()
            return
        }

        videoOutput.alwaysDiscardsLateVideoFrames = true // Prevent frame backlog.
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange]
        videoOutput.setSampleBufferDelegate(self, queue: cameraQueue)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        if let connection = videoOutput.connection(with: .video) {
            connection.videoOrientation = .portrait
        }

        session.commitConfiguration()
        isConfigured = true
    }
}

extension CameraEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Never retain CMSampleBuffer beyond this scope. Immediately forward.
        sampleBufferPublisher.send(sampleBuffer)
    }
}

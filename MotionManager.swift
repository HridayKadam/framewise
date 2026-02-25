import Foundation
import CoreMotion
import Combine

final class MotionManager {
    static let shared = MotionManager()

    private let manager = CMMotionManager()
    private let subject = CurrentValueSubject<Double, Never>(0) // roll in radians
    var horizonAnglePublisher: AnyPublisher<Double, Never> { subject.eraseToAnyPublisher() }

    private init() {}

    func start() {
        guard manager.isDeviceMotionAvailable else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 60.0
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let roll = motion?.attitude.roll else { return }
            self?.subject.send(roll)
        }
    }

    func stop() { manager.stopDeviceMotionUpdates() }
}

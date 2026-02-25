import Foundation
import Combine
import SwiftUI

#if os(iOS)
import ARKit
import RealityKit

final class AROverlayEngine: NSObject, ObservableObject {
    @Published var isTrackingLimited: Bool = false
    @Published var overlayOpacity: Double = 0.5

    private let arView = ARView(frame: .zero)
    private let anchor = AnchorEntity(world: .zero)

    private let gridEntity = ModelEntity()
    private let horizonEntity = ModelEntity()
    private let arrowEntity = ModelEntity()
    private let crosshairEntity = ModelEntity()

    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupScene()
    }

    func makeARView() -> ARView { arView }

    func start(configuration: ARWorldTrackingConfiguration = ARWorldTrackingConfiguration()) {
        configuration.worldAlignment = .gravity
        arView.session.delegate = self
        arView.automaticallyConfigureSession = false
        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }

    func stop() { arView.session.pause() }

    private func setupScene() {
        arView.scene.anchors.append(anchor)

        // Create reusable overlays once.
        let gridMesh = MeshResource.generatePlane(width: 1.0, depth: 1.0)
        gridEntity.model = ModelComponent(mesh: gridMesh, materials: [SimpleMaterial(color: .white.withAlphaComponent(0.15), isMetallic: false)])
        gridEntity.position = [0, 0, -1]
        anchor.addChild(gridEntity)

        let horizonMesh = MeshResource.generateBox(size: 0.002)
        horizonEntity.model = ModelComponent(mesh: horizonMesh, materials: [SimpleMaterial(color: .yellow.withAlphaComponent(0.9), isMetallic: false)])
        horizonEntity.scale = [1.5, 0.002, 0.002]
        horizonEntity.position = [0, 0, -0.8]
        anchor.addChild(horizonEntity)

        let arrowMesh = MeshResource.generateArrow()
        arrowEntity.model = ModelComponent(mesh: arrowMesh, materials: [SimpleMaterial(color: .cyan.withAlphaComponent(0.9), isMetallic: false)])
        arrowEntity.scale = [0.05, 0.05, 0.05]
        arrowEntity.position = [0.3, 0, -0.8]
        anchor.addChild(arrowEntity)

        let crossMesh = MeshResource.generateSphere(radius: 0.002)
        crosshairEntity.model = ModelComponent(mesh: crossMesh, materials: [SimpleMaterial(color: .white, isMetallic: false)])
        crosshairEntity.position = [0, 0, -0.8]
        anchor.addChild(crosshairEntity)
    }

    func updateOpacity(for tier: CompositionScore.Tier) {
        switch tier {
        case .excellent: overlayOpacity = 1.0
        case .good: overlayOpacity = 0.8
        case .fair: overlayOpacity = 0.5
        case .poor: overlayOpacity = 0.25
        }
        // Apply to materials without recreating entities.
        func setOpacity(_ entity: ModelEntity) {
            entity.model?.materials = entity.model?.materials.compactMap { material in
                if var simple = material as? SimpleMaterial {
                    let base = simple.color
                    simple.color = .init(tint: base.tint, texture: nil, tintColor: base.tint.withAlphaComponent(overlayOpacity))
                    return simple
                }
                return material
            } ?? []
        }
        setOpacity(gridEntity)
        setOpacity(horizonEntity)
        setOpacity(arrowEntity)
        setOpacity(crosshairEntity)
    }
}

extension AROverlayEngine: ARSessionDelegate {
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        switch camera.trackingState {
        case .normal: isTrackingLimited = false
        default: isTrackingLimited = true
        }
    }
}

fileprivate extension MeshResource {
    static func generateArrow() -> MeshResource {
        // Simple arrow: cone + cylinder
        let shaft = try! MeshResource.generateBox(width: 0.01, height: 0.002, depth: 0.2)
        let head = try! MeshResource.generateCone(topRadius: 0, bottomRadius: 0.02, height: 0.04)
        var combined = shaft
        combined += head.transformed(by: .init(translation: [0, 0, -0.12]))
        return combined
    }
}
#else
final class AROverlayEngine: ObservableObject {
    @Published var isTrackingLimited: Bool = false
    @Published var overlayOpacity: Double = 0.5
    func start() {}
    func stop() {}
    func updateOpacity(for tier: CompositionScore.Tier) {}
    func makeARView() -> NSView { NSView() }
}
#endif

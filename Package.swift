// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "FrameWise",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .executable(name: "FrameWise", targets: ["FrameWise"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "FrameWise",
            dependencies: [],
            path: ".",
            exclude: [
                "README.md",
                "README 2.md",
                ".gitignore"
            ],
            sources: [
                "AROverlayEngine.swift",
                "AccessibilityManager.swift",
                "AppCoordinator.swift",
                "CameraEngine.swift",
                "CompositionScorer.swift",
                "DesignSystem.swift",
                "FeatureExtractor.swift",
                "FrameWiseApp.swift",
                "HapticEngine.swift",
                "MotionManager.swift",
                "VisionProcessor.swift",
                "RootView.swift"
            ]
        )
    ]
)

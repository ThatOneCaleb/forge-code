import SwiftUI
import SceneKit
import ForgeCodeEngine

/// A SwiftUI wrapper around a `SCNView` that renders a `FieldWorld` using
/// `RoboticsFieldScene`. Mirrors the `Field3DView` / `UIViewRepresentable` pattern.
///
/// Pass `onSceneReady` to receive the `RoboticsFieldScene` after the
/// `SCNView` is set up so the caller can drive playback.
struct RoboticsFieldView: UIViewRepresentable {
    let world: FieldWorld

    /// Called once on the main actor immediately after the scene is built.
    var onSceneReady: (@MainActor (RoboticsFieldScene) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.04, green: 0.05, blue: 0.10, alpha: 1)

        // 4x MSAA for crisp edges on table walls and mat border
        scnView.antialiasingMode = .multisampling4X

        // PBR rendering requires these to be off (we supply all lights ourselves)
        scnView.autoenablesDefaultLighting = false

        // Allow kids to orbit/tilt/pinch — proves the scene is real 3D.
        // Default pointOfView is our hero angle; they can freely orbit from there.
        scnView.allowsCameraControl = true
        scnView.defaultCameraController.interactionMode = .orbitTurntable
        scnView.isUserInteractionEnabled = true

        let scene = RoboticsFieldScene(world: world)
        scnView.scene = scene.scnScene
        scnView.pointOfView = scene.cameraNode

        // Continuous rendering keeps HDR/bloom/SSAO updating every frame
        scnView.rendersContinuously = true
        scnView.preferredFramesPerSecond = 60

        Task { @MainActor in
            onSceneReady?(scene)
        }
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

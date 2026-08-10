import SwiftUI
import SceneKit
import ForgeCodeEngine

// MARK: - Coordinate helpers

// Engine convention: (x, y), origin bottom-left, +y is "up the board."
// World convention (SceneKit y-up): engine (x, y) → world (x, 0, -y).
// A cell that is 1 engine unit wide occupies 1 world unit (1 m).
// The field is centred at the world origin, so we subtract half the
// board dimensions when placing tiles.

private extension Position {
    /// World-space centre of this cell, on the ground plane (y = 0).
    func worldPosition(gridWidth: Int, gridHeight: Int) -> SCNVector3 {
        let halfW = Float(gridWidth) * 0.5
        let halfH = Float(gridHeight) * 0.5
        return SCNVector3(
            Float(x) + 0.5 - halfW,   // centred in cell, offset to origin
            0,
            -(Float(y) + 0.5 - halfH) // flip y → z, centre
        )
    }
}

private extension Direction {
    /// Y-axis rotation (radians) so the robot's +z face points in the
    /// engine direction. Engine "up" = −z in world → robot faces −z → 0 rad.
    var yRotation: Float {
        switch self {
        case .up:    return 0
        case .right: return -.pi / 2
        case .down:  return .pi
        case .left:  return .pi / 2
        }
    }
}

// MARK: - Field3DView

/// A SceneKit-rendered 3D view of a `Challenge`.
///
/// The themed mat, obstacles, goal marker, and robot are built from
/// SceneKit primitives — no third-party packages, no external assets.
/// Call `playFrames(_:)` to animate a `[RobotState]` trace at ~0.3 s/step.
///
/// Theme: "Reef Rescue" — teal/aqua mat, coral obstacles, glowing ring goal.
struct Field3DView: UIViewRepresentable {
    let challenge: Challenge

    /// Called once after the view is created so the owner can hold a
    /// reference and later call `playFrames(_:)`.
    var onSceneReady: ((Field3DScene) -> Void)?

    func makeUIView(context: Context) -> SCNView {
        let scnView = SCNView()
        scnView.backgroundColor = UIColor(red: 0.05, green: 0.12, blue: 0.20, alpha: 1) // deep ocean bg
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false

        let scene = Field3DScene(challenge: challenge)
        scnView.scene = scene.scnScene
        scnView.pointOfView = scene.cameraNode

        // Surface selection/camera control intentionally disabled
        scnView.isUserInteractionEnabled = false

        onSceneReady?(scene)
        return scnView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {}
}

// MARK: - Field3DScene

/// Owns the SceneKit scene graph for a single challenge field.
/// Separated from the `UIViewRepresentable` so the SwiftUI owner can
/// call `playFrames(_:)` without keeping a reference to the `SCNView`.
final class Field3DScene {
    let scnScene: SCNScene
    let cameraNode: SCNNode
    private let robotNode: SCNNode
    private let challenge: Challenge

    init(challenge: Challenge) {
        self.challenge = challenge
        scnScene = SCNScene()
        scnScene.background.contents = UIColor(red: 0.05, green: 0.12, blue: 0.20, alpha: 1)

        let gridW = challenge.grid.width
        let gridH = challenge.grid.height

        // --- Lighting ---
        // Ambient fill
        let ambientNode = SCNNode()
        let ambient = SCNLight()
        ambient.type = .ambient
        ambient.color = UIColor(white: 0.35, alpha: 1)
        ambientNode.light = ambient
        scnScene.rootNode.addChildNode(ambientNode)

        // Main directional (sun angle)
        let sunNode = SCNNode()
        let sun = SCNLight()
        sun.type = .directional
        sun.color = UIColor(white: 0.9, alpha: 1)
        sun.castsShadow = true
        sun.shadowRadius = 4
        sun.shadowColor = UIColor(white: 0, alpha: 0.4)
        sunNode.light = sun
        sunNode.eulerAngles = SCNVector3(-Float.pi / 4, Float.pi / 6, 0)
        scnScene.rootNode.addChildNode(sunNode)

        // Soft fill from below/side (bounce light)
        let fillNode = SCNNode()
        let fill = SCNLight()
        fill.type = .omni
        fill.color = UIColor(red: 0.4, green: 0.8, blue: 0.9, alpha: 1)
        fill.intensity = 400
        fill.attenuationStartDistance = 5
        fill.attenuationEndDistance = 25
        fillNode.light = fill
        fillNode.position = SCNVector3(0, 3, Float(gridH) * 0.5)
        scnScene.rootNode.addChildNode(fillNode)

        // --- Mat (teal/aqua field surface) ---
        let matGeo = SCNBox(
            width: CGFloat(gridW),
            height: 0.08,
            length: CGFloat(gridH),
            chamferRadius: 0.05
        )
        let matMat = SCNMaterial()
        matMat.diffuse.contents = UIColor(red: 0.05, green: 0.55, blue: 0.60, alpha: 1)
        matMat.specular.contents = UIColor(white: 0.3, alpha: 1)
        matGeo.materials = [matMat]
        let matNode = SCNNode(geometry: matGeo)
        matNode.position = SCNVector3(0, -0.04, 0) // top surface sits at y=0
        scnScene.rootNode.addChildNode(matNode)

        // --- Grid lines (subtle raised lines on the mat) ---
        let lineColor = UIColor(red: 0.10, green: 0.45, blue: 0.50, alpha: 0.6)
        let lineThickness: CGFloat = 0.04
        let lineHeight: CGFloat = 0.02

        let halfW = CGFloat(gridW) * 0.5
        let halfH = CGFloat(gridH) * 0.5

        // Vertical grid lines (along z)
        for col in 1..<gridW {
            let vGeo = SCNBox(width: lineThickness, height: lineHeight, length: CGFloat(gridH), chamferRadius: 0)
            let vMat = SCNMaterial()
            vMat.diffuse.contents = lineColor
            vGeo.materials = [vMat]
            let vNode = SCNNode(geometry: vGeo)
            vNode.position = SCNVector3(Float(col) - Float(halfW), Float(lineHeight / 2), 0)
            scnScene.rootNode.addChildNode(vNode)
        }
        // Horizontal grid lines (along x)
        for row in 1..<gridH {
            let hGeo = SCNBox(width: CGFloat(gridW), height: lineHeight, length: lineThickness, chamferRadius: 0)
            let hMat = SCNMaterial()
            hMat.diffuse.contents = lineColor
            hGeo.materials = [hMat]
            let hNode = SCNNode(geometry: hGeo)
            hNode.position = SCNVector3(0, Float(lineHeight / 2), -(Float(row) - Float(halfH)))
            scnScene.rootNode.addChildNode(hNode)
        }

        // --- Obstacles (coral-colored raised blocks) ---
        for obstacle in challenge.grid.obstacles {
            let blockGeo = SCNBox(width: 0.85, height: 0.6, length: 0.85, chamferRadius: 0.08)
            let blockMat = SCNMaterial()
            blockMat.diffuse.contents = UIColor(red: 0.85, green: 0.35, blue: 0.25, alpha: 1) // coral
            blockMat.specular.contents = UIColor(white: 0.4, alpha: 1)
            blockGeo.materials = [blockMat]
            let blockNode = SCNNode(geometry: blockGeo)
            var worldPos = obstacle.worldPosition(gridWidth: gridW, gridHeight: gridH)
            worldPos.y = 0.3 // half of height
            blockNode.position = worldPos
            scnScene.rootNode.addChildNode(blockNode)
        }

        // --- Goal marker (glowing aqua ring + flag post) ---
        let goalPos = challenge.goal.worldPosition(gridWidth: gridW, gridHeight: gridH)

        // Base pad
        let padGeo = SCNCylinder(radius: 0.38, height: 0.06)
        let padMat = SCNMaterial()
        padMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1) // gold
        padMat.emission.contents = UIColor(red: 0.6, green: 0.5, blue: 0.0, alpha: 1)
        padGeo.materials = [padMat]
        let padNode = SCNNode(geometry: padGeo)
        padNode.position = SCNVector3(goalPos.x, 0.03, goalPos.z)
        scnScene.rootNode.addChildNode(padNode)

        // Outer ring
        let torusGeo = SCNTorus(ringRadius: 0.38, pipeRadius: 0.06)
        let torusMat = SCNMaterial()
        torusMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1)
        torusMat.emission.contents = UIColor(red: 0.8, green: 0.6, blue: 0.0, alpha: 1)
        torusMat.specular.contents = UIColor.white
        torusGeo.materials = [torusMat]
        let torusNode = SCNNode(geometry: torusGeo)
        torusNode.position = SCNVector3(goalPos.x, 0.12, goalPos.z)
        scnScene.rootNode.addChildNode(torusNode)

        // Flag post
        let poleGeo = SCNCylinder(radius: 0.04, height: 1.0)
        let poleMat = SCNMaterial()
        poleMat.diffuse.contents = UIColor(white: 0.9, alpha: 1)
        poleGeo.materials = [poleMat]
        let poleNode = SCNNode(geometry: poleGeo)
        poleNode.position = SCNVector3(goalPos.x, 0.5, goalPos.z)
        scnScene.rootNode.addChildNode(poleNode)

        // Flag pennant (flattened box)
        let flagGeo = SCNBox(width: 0.35, height: 0.22, length: 0.02, chamferRadius: 0.01)
        let flagMat = SCNMaterial()
        flagMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1)
        flagMat.emission.contents = UIColor(red: 0.4, green: 0.34, blue: 0.0, alpha: 1)
        flagGeo.materials = [flagMat]
        let flagNode = SCNNode(geometry: flagGeo)
        flagNode.position = SCNVector3(goalPos.x + 0.175, 0.89, goalPos.z)
        scnScene.rootNode.addChildNode(flagNode)

        // --- Robot ---
        robotNode = Self.makeRobot()
        let startPos = challenge.start.position.worldPosition(gridWidth: gridW, gridHeight: gridH)
        robotNode.position = SCNVector3(startPos.x, 0.22, startPos.z)
        robotNode.eulerAngles.y = challenge.start.facing.yRotation
        scnScene.rootNode.addChildNode(robotNode)

        // --- Camera ---
        // Overhead-angled view that frames the whole field with margin.
        cameraNode = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 50
        camera.zNear = 0.1
        camera.zFar = 100
        cameraNode.camera = camera

        let fieldDiag = sqrt(Double(gridW * gridW + gridH * gridH))
        let camDist = Float(fieldDiag) * 0.75
        let camHeight = Float(fieldDiag) * 0.8
        // Slightly offset toward viewer (positive z in world = toward camera).
        cameraNode.position = SCNVector3(0, camHeight, camDist)
        cameraNode.eulerAngles = SCNVector3(-atan2(camHeight, camDist) * 0.9, 0, 0)
        scnScene.rootNode.addChildNode(cameraNode)
    }

    // MARK: - Robot geometry

    private static func makeRobot() -> SCNNode {
        let root = SCNNode()

        // Body: rounded box
        let bodyGeo = SCNBox(width: 0.65, height: 0.42, length: 0.65, chamferRadius: 0.10)
        let bodyMat = SCNMaterial()
        bodyMat.diffuse.contents = UIColor(red: 0.20, green: 0.45, blue: 0.85, alpha: 1) // cobalt blue
        bodyMat.specular.contents = UIColor(white: 0.6, alpha: 1)
        bodyGeo.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: bodyGeo)
        root.addChildNode(bodyNode)

        // Direction indicator: a bright chevron/wedge on the front face (−z).
        // We use a cone pointing in −z (the "up" / forward direction in world).
        let noseGeo = SCNCone(topRadius: 0, bottomRadius: 0.12, height: 0.20)
        let noseMat = SCNMaterial()
        noseMat.diffuse.contents = UIColor(red: 1.0, green: 0.85, blue: 0.1, alpha: 1) // gold nose
        noseMat.emission.contents = UIColor(red: 0.4, green: 0.3, blue: 0.0, alpha: 1)
        noseGeo.materials = [noseMat]
        let noseNode = SCNNode(geometry: noseGeo)
        // Rotate so cone tip points in −z (forward when robot faces "up" = −z)
        noseNode.eulerAngles = SCNVector3(Float.pi / 2, 0, 0) // tip points −z
        noseNode.position = SCNVector3(0, 0.05, -0.40)
        root.addChildNode(noseNode)

        // Eyes (two small spheres, slightly above mid face)
        for xOff: Float in [-0.12, 0.12] {
            let eyeGeo = SCNSphere(radius: 0.07)
            let eyeMat = SCNMaterial()
            eyeMat.diffuse.contents = UIColor(red: 0.1, green: 0.9, blue: 0.9, alpha: 1) // teal
            eyeMat.emission.contents = UIColor(red: 0.0, green: 0.3, blue: 0.3, alpha: 1)
            eyeGeo.materials = [eyeMat]
            let eyeNode = SCNNode(geometry: eyeGeo)
            eyeNode.position = SCNVector3(xOff, 0.10, -0.33)
            root.addChildNode(eyeNode)
        }

        // Wheels (four dark cylinders)
        let wheelPositions: [(Float, Float, Float)] = [
            (-0.35, -0.15, -0.22),
            ( 0.35, -0.15, -0.22),
            (-0.35, -0.15,  0.22),
            ( 0.35, -0.15,  0.22)
        ]
        for (wx, wy, wz) in wheelPositions {
            let wheelGeo = SCNCylinder(radius: 0.10, height: 0.08)
            let wheelMat = SCNMaterial()
            wheelMat.diffuse.contents = UIColor(white: 0.15, alpha: 1)
            wheelGeo.materials = [wheelMat]
            let wheelNode = SCNNode(geometry: wheelGeo)
            // Rotate cylinder so its axis aligns with X (wheel rolls along X).
            wheelNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            wheelNode.position = SCNVector3(wx, wy, wz)
            root.addChildNode(wheelNode)
        }

        return root
    }

    // MARK: - Frame playback

    /// Animate the robot through a sequence of `RobotState` frames at
    /// ~0.3 s/step, matching the 2D playback cadence in `SimulatorViewModel`.
    ///
    /// The caller is responsible for calling this only once per run (not
    /// re-entrant). Safe to call from the main actor.
    func playFrames(_ frames: [RobotState], completion: @escaping @Sendable () -> Void) {
        let gridW = challenge.grid.width
        let gridH = challenge.grid.height
        let stepDuration: TimeInterval = 0.28

        var actions: [SCNAction] = []
        for frame in frames {
            let worldPos = frame.position.worldPosition(gridWidth: gridW, gridHeight: gridH)
            let targetPos = SCNVector3(worldPos.x, 0.22, worldPos.z)
            let targetAngle = frame.facing.yRotation

            let moveAction = SCNAction.move(to: targetPos, duration: stepDuration)
            moveAction.timingMode = .easeInEaseOut

            let rotateAction = SCNAction.rotateTo(
                x: 0,
                y: CGFloat(targetAngle),
                z: 0,
                duration: stepDuration * 0.5,
                usesShortestUnitArc: true
            )
            rotateAction.timingMode = .easeInEaseOut

            let group = SCNAction.group([moveAction, rotateAction])
            actions.append(group)
        }

        let sequence = SCNAction.sequence(actions)
        robotNode.runAction(sequence) {
            DispatchQueue.main.async { completion() }
        }
    }

    /// Reset the robot to the challenge's starting state.
    func resetRobot() {
        robotNode.removeAllActions()
        let gridW = challenge.grid.width
        let gridH = challenge.grid.height
        let startPos = challenge.start.position.worldPosition(gridWidth: gridW, gridHeight: gridH)
        robotNode.position = SCNVector3(startPos.x, 0.22, startPos.z)
        robotNode.eulerAngles.y = challenge.start.facing.yRotation
    }
}

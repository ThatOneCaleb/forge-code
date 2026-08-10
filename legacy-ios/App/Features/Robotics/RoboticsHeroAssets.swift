import SceneKit
import UIKit

// MARK: - RoboticsHeroAssets
//
// Loads bundled 3D "hero" models for the robotics field, with a graceful
// procedural fallback when a model is absent. This is how the HYBRID visual
// plan (see the project memory "robotics-3d-visual-direction") gets real,
// recognizable 3D models onto the field instead of abstract primitives.
//
// ── Models we ship (Kenney "Space Kit", CC0 / public domain) ──────────────────
// Bundled under `App/Resources/RoboticsHeroModels/` as Collada `.dae` (SceneKit
// loads these natively; the Kenney models bake their colors into the file, so no
// external textures are needed). CC0 means no attribution required and safe for
// the App Store kids category. Source: kenney.nl/assets/space-kit.
//   • rover.dae                 → the hero rover
//   • prop_<type>.dae           → a mission prop per item type (barrel, cargo, …)
//   • obstacle_<name>.dae       → a field obstacle model (rock, meteor, …)
//
// A caller gets `nil` when no matching file is present, and falls back to the
// existing procedural geometry — so the app always renders.
enum RoboticsHeroAssets {

    /// Optional bundle subdirectory (folder reference) that hero models may live in.
    static let subdirectory = "RoboticsHeroModels"

    /// Supported model file extensions, in priority order. `.dae`/`.scn`/`.usd*`
    /// all load through `SCNScene(url:)`.
    private static let extensions = ["usdz", "usdc", "scn", "dae"]

    // MARK: - Generic load

    /// Load a bundled model by base name into a fresh container node, or `nil`.
    static func loadNode(named name: String) -> SCNNode? {
        for ext in extensions {
            let url = Bundle.main.url(forResource: name, withExtension: ext,
                                      subdirectory: subdirectory)
                   ?? Bundle.main.url(forResource: name, withExtension: ext)
            guard let url else { continue }
            // NOTE: models are shipped as USD (.usdc/.usdz) or .scn — iOS SceneKit
            // cannot load Collada .dae at runtime, so .dae is a build-time-only format.
            guard let scene = try? SCNScene(url: url, options: [
                .checkConsistency: false,
                .flattenScene:     false,
                .convertToYUp:     true
            ]) else { continue }

            let container = SCNNode()
            for child in scene.rootNode.childNodes {
                child.removeFromParentNode()
                container.addChildNode(child)
            }
            enableShadows(on: container)
            return container
        }
        return nil
    }

    // MARK: - Rover

    /// Load the rover hero model, normalized (centered, base on the mat, facing
    /// north = −Z) and returned in the same labelled tuple shape as the
    /// procedural `makeRobotNodes()`. Arm/gripper fall back to inert empty nodes
    /// when the model has no rig, so playback never tilts the whole body.
    static func loadRobot() -> (root: SCNNode, arm: SCNNode, gripper: SCNNode)? {
        guard let container = loadNode(named: "rover") else { return nil }
        normalize(container, maxDimension: 0.62, baseAtOrigin: true, yawDegrees: 180)

        let root = SCNNode()
        root.addChildNode(container)

        let arm = container.childNode(withName: "ArmPivot", recursively: true)
            ?? { let n = SCNNode(); root.addChildNode(n); return n }()
        let gripper = arm.childNode(withName: "GripperPivot", recursively: true)
            ?? { let n = SCNNode(); arm.addChildNode(n); return n }()
        return (root, arm, gripper)
    }

    // MARK: - Props / obstacles

    /// Load a mission-prop model for the given item type (e.g. "barrel"), or nil.
    static func loadItem(type: String?) -> SCNNode? {
        guard let type = type?.lowercased(), !type.isEmpty else { return nil }
        guard let node = loadNode(named: "prop_\(type)") else { return nil }
        normalize(node, maxDimension: 0.95, baseAtOrigin: true, yawDegrees: 0)
        return node
    }

    /// Load an obstacle model by key (e.g. "boulder", "crater"), fit to `targetSize`, or nil.
    static func loadObstacle(named key: String, targetSize: Float) -> SCNNode? {
        guard let node = loadNode(named: "obstacle_\(key)") else { return nil }
        normalize(node, maxDimension: targetSize, baseAtOrigin: true, yawDegrees: 0)
        return node
    }

    /// Load a zone landmark model by zone kind ("deposit"/"detection"/"goal"), or nil.
    static func loadZone(kind: String, targetSize: Float) -> SCNNode? {
        guard let node = loadNode(named: "zone_\(kind)") else { return nil }
        normalize(node, maxDimension: targetSize, baseAtOrigin: true, yawDegrees: 0)
        return node
    }

    // MARK: - Normalization

    /// Recenter (x/z), drop the base to y=0, uniformly scale so the largest
    /// horizontal footprint dimension ≈ `maxDimension`, and apply a yaw so the
    /// model faces the engine's north (−Z). Operates by wrapping the model in an
    /// inner transform node so the outer node's scale stays free for callers.
    static func normalize(_ node: SCNNode, maxDimension: Float,
                          baseAtOrigin: Bool, yawDegrees: Float) {
        // Hierarchy: node(scale) → yaw(rotation) → inner(recenter) → children.
        // Recentering happens in the same space as measurement; yaw wraps it.
        // NOTE: measure with the node's own `boundingBox` (includes children) —
        // `flattenedClone()` returns a ZERO box for USD-backed geometry.
        let inner = SCNNode()
        for c in node.childNodes { c.removeFromParentNode(); inner.addChildNode(c) }
        let yaw = SCNNode()
        yaw.eulerAngles = SCNVector3(0, yawDegrees * .pi / 180, 0)
        yaw.addChildNode(inner)
        node.addChildNode(yaw)

        let (minV, maxV) = inner.boundingBox
        let sizeX = maxV.x - minV.x
        let sizeY = maxV.y - minV.y
        let sizeZ = maxV.z - minV.z
        let footprint = max(sizeX, sizeZ)
        guard footprint.isFinite, footprint > 0.0001 else { return }

        // Recenter horizontally and (optionally) drop the base to y=0.
        let cx = (minV.x + maxV.x) * 0.5
        let cz = (minV.z + maxV.z) * 0.5
        let cy = baseAtOrigin ? minV.y : (minV.y + maxV.y) * 0.5
        inner.position = SCNVector3(-cx, -cy, -cz)

        // Fit: scale the OUTER node so footprint (or height if taller) ≈ target.
        // (Yaw is about Y, so footprint/height are rotation-invariant here.)
        let largest = max(footprint, sizeY)
        node.scale = SCNVector3(maxDimension / largest,
                                maxDimension / largest,
                                maxDimension / largest)
    }

    // MARK: - Helpers

    private static func enableShadows(on node: SCNNode) {
        node.enumerateChildNodes { child, _ in
            if child.geometry != nil { child.castsShadow = true }
        }
    }
}

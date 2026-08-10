import SceneKit
import UIKit
import ForgeCodeEngine

// MARK: - Coordinate mapping
//
// Engine convention: (x, y) in centimetres, +x = east, +y = north (up the field).
// SceneKit is y-up, field on the XZ plane.
// Mapping: engine(x, y) → world(x * scale, 0, -y * scale)
// where scale = 1/10 (1 world unit = 10 cm), so a 240 cm field → 24 world units.
// Heading: engine 0° = north (+y) → robot faces -z in SceneKit → y-rotation = 0.
// CW engine heading → CW in SceneKit (positive Y rotation).

private let kScale: Float = 0.1   // 10 cm → 1 SceneKit unit

private func worldX(_ cmX: Double) -> Float { Float(cmX) * kScale }
private func worldZ(_ cmY: Double) -> Float { -Float(cmY) * kScale }
private func worldXZ(_ pos: Vec2) -> (x: Float, z: Float) { (worldX(pos.x), worldZ(pos.y)) }

/// Engine headingDegrees (0=north, CW) → SceneKit Y rotation (radians).
/// Engine north = robot faces -z in SceneKit = yRot 0.
/// Engine east (90°) = robot faces +x = yRot = -π/2 (CW in engine, so subtract).
private func headingToYRot(_ deg: Double) -> Float {
    // SceneKit rotates CW looking down (+Y), engine CW = same sense.
    // engine 0° (north/-z) → yRot 0. engine 90° (east/+x) → yRot π/2?
    // Actually: engine heading 0° = north = -z face. 90° = east = +x face.
    // A SceneKit yRot of +π/2 rotates the -z face to point in +x. So:
    return Float(deg) * .pi / 180.0
}

// MARK: - Filmic color helpers
// All zone/region colors are desaturated ~15% and warmed slightly for a printed-mat look.

private func filmicColor(_ name: String?) -> UIColor {
    switch name?.lowercased() {
    case "red":    return UIColor(red: 0.78, green: 0.24, blue: 0.20, alpha: 1)
    case "blue":   return UIColor(red: 0.22, green: 0.42, blue: 0.78, alpha: 1)
    case "green":  return UIColor(red: 0.20, green: 0.62, blue: 0.28, alpha: 1)
    case "yellow": return UIColor(red: 0.90, green: 0.76, blue: 0.18, alpha: 1)
    case "orange": return UIColor(red: 0.88, green: 0.46, blue: 0.14, alpha: 1)
    case "purple": return UIColor(red: 0.52, green: 0.20, blue: 0.72, alpha: 1)
    case "teal":   return UIColor(red: 0.14, green: 0.60, blue: 0.64, alpha: 1)
    case "white":  return UIColor(red: 0.92, green: 0.92, blue: 0.90, alpha: 1)
    default:       return UIColor(red: 0.48, green: 0.48, blue: 0.46, alpha: 1)
    }
}

// Darker/shadowed variant of a zone color (used for outlines, rings)
private func filmicColorDark(_ name: String?) -> UIColor {
    filmicColor(name).darkened(by: 0.22)
}

// Lighter highlight variant
private func filmicColorLight(_ name: String?) -> UIColor {
    filmicColor(name).lightened(by: 0.18)
}

// MARK: - PBR material factory

private func pbrMaterial(
    diffuse: Any,           // UIColor or UIImage
    metalness: CGFloat = 0.0,
    roughness: CGFloat = 0.7,
    emission: UIColor? = nil,
    normal: UIImage? = nil
) -> SCNMaterial {
    let m = SCNMaterial()
    m.lightingModel = .physicallyBased
    m.diffuse.contents  = diffuse
    m.metalness.contents = metalness as NSNumber
    m.roughness.contents = roughness as NSNumber
    if let e = emission { m.emission.contents = e }
    if let n = normal   { m.normal.contents   = n }
    return m
}

// MARK: - RoboticsFieldScene

/// Owns the SceneKit scene graph for one continuous-coordinate `FieldWorld`.
/// Call `play(snapshots:onFrameIndex:completion:)` to animate the robot through
/// a `MatchRun`'s keyframe trace. All mutations must happen on the main actor.
@MainActor
final class RoboticsFieldScene {

    let scnScene:   SCNScene
    let cameraNode: SCNNode

    private let world:       FieldWorld
    private(set) var robotNode:   SCNNode
    private(set) var armNode:     SCNNode      // pivots on the robot body
    private(set) var gripperNode: SCNNode      // translates on arm tip

    /// Map from item id → its node in the scene (for live position updates).
    private(set) var itemNodes: [String: SCNNode] = [:]

    /// Drive-wheel axle nodes that spin while the rover moves (realism).
    private var wheelNodes: [SCNNode] = []
    /// Emissive glow plane per deposit zone, pulsed when an item is delivered.
    private var depositGlowNodes: [String: SCNNode] = [:]
    /// Tracks the held object across playback frames to detect release events.
    private var lastHeldId: String?
    /// Animatable node per mechanism id (the part that moves on activation).
    private var mechanismNodes: [String: SCNNode] = [:]
    /// Initial position per mechanism node, for restoring on reset.
    private var mechanismResetTransforms: [String: SCNVector3] = [:]
    /// Mechanism ids already animated to their activated pose (playback bookkeeping).
    private var activatedMechs: Set<String> = []

    // Height of the table surface above the ground plane
    private let tableTopY: Float = 0.30

    // The rover is drawn larger than life relative to the field so it reads as
    // the hero of the scene (a real robot on a 2.4 m field would be a speck).
    private let robotScale: Float = 2.6
    // Whether a bundled hero rover model loaded (vs procedural geometry).
    private var usingHeroRobot = false
    // Y of the rover's origin so it rests on the mat. Hero models are normalized
    // with their base at the origin, so they sit almost flush; the procedural
    // rover is modelled around its centre and needs a larger lift.
    private var robotRestY: Float { tableTopY + (usingHeroRobot ? 0.02 : 0.33) }

    // MARK: - Init

    init(world: FieldWorld) {
        self.world = world
        scnScene   = SCNScene()

        let wW = Float(world.widthCm)  * kScale   // scene width  (e.g. 24 units)
        let wH = Float(world.heightCm) * kScale   // scene depth  (e.g. 24 units)
        let ttY = Float(0.30)                      // table surface Y

        // ---- Background: deep studio gradient ----
        scnScene.background.contents = Self.makeGradientBackground()

        // ---- Environment map: soft studio dome (warm top, cool bottom) ----
        // Provides realistic reflections + fill on all PBR surfaces.
        scnScene.lightingEnvironment.contents  = Self.makeEnvironmentMap()
        scnScene.lightingEnvironment.intensity = 0.55

        // ---- Lighting ----
        Self.addLighting(to: scnScene.rootNode, wW: wW, wH: wH, ttY: ttY)

        // ---- Ground plane (subtle dark floor, catches table shadow) ----
        let groundGeo = SCNFloor()
        let groundMat = pbrMaterial(
            diffuse: UIColor(red: 0.08, green: 0.08, blue: 0.10, alpha: 1),
            metalness: 0.04,
            roughness: 0.96
        )
        groundMat.diffuse.wrapS = .repeat
        groundMat.diffuse.wrapT = .repeat
        groundGeo.materials = [groundMat]
        groundGeo.reflectivity = 0.04
        let groundNode = SCNNode(geometry: groundGeo)
        groundNode.position = SCNVector3(0, 0, 0)
        groundNode.castsShadow = false
        scnScene.rootNode.addChildNode(groundNode)

        // ---- Table structure ----
        let tableThickness: Float = ttY
        let tableLip:       Float = 0.30
        let tableW = wW + tableLip * 2
        let tableD = wH + tableLip * 2
        let tableOriginX = wW * 0.5
        let tableOriginZ = -wH * 0.5

        // Table slab with wood-grain texture
        let slabGeo = SCNBox(width:  CGFloat(tableW),
                              height: CGFloat(tableThickness),
                              length: CGFloat(tableD),
                              chamferRadius: 0.012)
        let woodTexture = Self.makeWoodGrainTexture(width: 512, height: 256)
        let slabMat = pbrMaterial(
            diffuse: woodTexture,
            metalness: 0.0,
            roughness: 0.82
        )
        slabMat.diffuse.wrapS = .repeat
        slabMat.diffuse.wrapT = .repeat
        slabGeo.materials = [slabMat, slabMat, slabMat, slabMat, slabMat, slabMat]
        let slabNode = SCNNode(geometry: slabGeo)
        slabNode.position = SCNVector3(tableOriginX, tableThickness * 0.5, tableOriginZ)
        slabNode.castsShadow = true
        scnScene.rootNode.addChildNode(slabNode)

        // Table legs (four corners, dark metal tube look)
        let legH: Float = 1.8
        let legSize: Float = 0.16
        let legMat = pbrMaterial(
            diffuse: UIColor(red: 0.16, green: 0.14, blue: 0.12, alpha: 1),
            metalness: 0.05, roughness: 0.88
        )
        for (lx, lz) in [(tableLip * 0.5, tableLip * 0.5),
                          (tableW - tableLip * 0.5, tableLip * 0.5),
                          (tableLip * 0.5, tableD - tableLip * 0.5),
                          (tableW - tableLip * 0.5, tableD - tableLip * 0.5)] as [(Float, Float)] {
            let legGeo = SCNBox(width: CGFloat(legSize), height: CGFloat(legH),
                                length: CGFloat(legSize), chamferRadius: 0.01)
            legGeo.materials = [legMat]
            let legNode = SCNNode(geometry: legGeo)
            let legWorldX = lx - tableLip
            let legWorldZ = -(lz - tableLip)
            legNode.position = SCNVector3(legWorldX, tableThickness - legH * 0.5, legWorldZ)
            legNode.castsShadow = true
            scnScene.rootNode.addChildNode(legNode)
        }

        // ---- Mat (one high-resolution printed texture — all zones/lines painted in) ----
        // The mat IS the field graphic. Everything is printed INTO this texture.
        // Only genuinely 3D geometry (goal rings, detection pad raised edges) gets
        // separate SceneKit geometry on top.
        let matThickness: Float = 0.012
        let matGeo = SCNBox(width: CGFloat(wW), height: CGFloat(matThickness),
                             length: CGFloat(wH), chamferRadius: 0)
        let matTexture = Self.makePrintedMatTexture(world: world)
        let matMat = pbrMaterial(
            diffuse: matTexture,
            metalness: 0.0,
            roughness: 0.88
        )
        matMat.writesToDepthBuffer = true
        matGeo.materials = [matMat]
        let matNode = SCNNode(geometry: matGeo)
        let matY = ttY + matThickness * 0.5
        matNode.position = SCNVector3(wW * 0.5, matY, -wH * 0.5)
        matNode.castsShadow = false
        scnScene.rootNode.addChildNode(matNode)

        // ---- Border walls (4 rails, wood-grain) ----
        Self.addBorderWalls(to: scnScene.rootNode, wW: wW, wH: wH, matY: matY,
                            woodTexture: woodTexture)

        // ---- 3D props on top of mat: goal rings (torus), detection pad raised trim ----
        // coloredRegions and zones are painted into the mat texture.
        // Only the genuinely 3D-readable goal rings and detection-pad edges are separate geometry.
        let baseY = matY + 0.008

        for zone in world.zones {
            let zW = Float(zone.rect.width)  * kScale
            let zH = Float(zone.rect.height) * kScale
            let zX = Float(zone.rect.x)      * kScale + zW * 0.5
            let zZ = -(Float(zone.rect.y)    * kScale + zH * 0.5)

            switch zone.kind {
            case .deposit:
                // Very low painted-curb (1 mm raised edge strip) for tactile reality
                let curbH: Float = 0.006
                let curbT: Float = max(min(zW, zH) * 0.04, 0.028)
                let curbMat = pbrMaterial(
                    diffuse: filmicColorDark(zone.color),
                    metalness: 0.0, roughness: 0.80
                )
                for (cx, cz, cw, cd) in [
                    (zX - zW * 0.5 + curbT * 0.5, zZ, curbT, zH),
                    (zX + zW * 0.5 - curbT * 0.5, zZ, curbT, zH),
                    (zX, zZ - zH * 0.5 + curbT * 0.5, zW, curbT),
                    (zX, zZ + zH * 0.5 - curbT * 0.5, zW, curbT)
                ] as [(Float, Float, Float, Float)] {
                    let g = SCNBox(width: CGFloat(cw), height: CGFloat(curbH),
                                   length: CGFloat(cd), chamferRadius: 0)
                    g.materials = [curbMat]
                    let n = SCNNode(geometry: g)
                    n.position = SCNVector3(cx, baseY + curbH * 0.5, cz)
                    n.castsShadow = false
                    scnScene.rootNode.addChildNode(n)
                }

                // Hidden emissive glow, pulsed when an item is delivered here.
                let glowGeo = SCNBox(width: CGFloat(zW * 0.92), height: 0.006,
                                     length: CGFloat(zH * 0.92), chamferRadius: 0.03)
                let glowMat = SCNMaterial()
                glowMat.lightingModel   = .constant
                glowMat.diffuse.contents  = filmicColorLight(zone.color)
                glowMat.emission.contents = filmicColorLight(zone.color)
                glowMat.writesToDepthBuffer = false
                glowGeo.materials = [glowMat]
                let glowNode = SCNNode(geometry: glowGeo)
                glowNode.position = SCNVector3(zX, baseY + 0.004, zZ)
                glowNode.opacity  = 0.0
                glowNode.castsShadow = false
                scnScene.rootNode.addChildNode(glowNode)
                depositGlowNodes[zone.id] = glowNode

            case .detection, .goal:
                // No abstract 3D rings — a real landmark model marks these zones
                // (satellite dish / launch structure), added below. The mat keeps
                // a calm labelled pad as the drive target.
                break
            }
        }

        // ---- Obstacles (real 3D models when available, else procedural) ----
        // Obstacles that a gate mechanism unlocks are drawn AS the gate (below),
        // not as rocks — skip them here.
        let gatedObstacleIds = Set(world.mechanisms.compactMap { $0.unlocksObstacleId })
        for obs in world.obstacles where !gatedObstacleIds.contains(obs.id) {
            let oW = max(Float(obs.rect.width) * kScale, 0.08)
            let oH = max(Float(obs.rect.height) * kScale, 0.08)
            let oX = Float(obs.rect.x) * kScale + oW * 0.5
            let oZ = -(Float(obs.rect.y) * kScale + oH * 0.5)
            let obsBaseY = ttY

            // Prefer bundled obstacle models (rock / crater / …).
            // Elongated obstacles become a natural RIDGE of several rocks with
            // deterministic size/heading variation, instead of one stretched or
            // lonely model — this is what makes rock walls read as terrain.
            let key = Self.obstacleKey(for: obs.id)
            let longSide  = max(oW, oH)
            let shortSide = min(oW, oH)
            if longSide / shortSide > 1.8,
               RoboticsHeroAssets.loadObstacle(named: "boulder", targetSize: 1) != nil {
                let rockSize = max(shortSide * 1.7, 0.9)
                let count = max(2, Int((longSide / (rockSize * 0.72)).rounded()))
                let horizontal = oW >= oH
                for i in 0..<count {
                    // Deterministic pseudo-variation from the index
                    let t = (Float(i) + 0.5) / Float(count)
                    let jitter  = Float((i * 7919) % 100) / 100.0 - 0.5
                    let vary    = 0.80 + Float((i * 104729) % 100) / 100.0 * 0.45
                    guard let rock = RoboticsHeroAssets.loadObstacle(
                        named: "boulder", targetSize: rockSize * vary) else { continue }
                    let px = horizontal ? (Float(obs.rect.x) * kScale + longSide * t)
                                        : oX + jitter * shortSide * 0.4
                    let pz = horizontal ? oZ + jitter * shortSide * 0.4
                                        : -(Float(obs.rect.y) * kScale + longSide * t)
                    rock.position = SCNVector3(px, ttY + 0.02, pz)
                    rock.eulerAngles.y = Float(i) * 1.7
                    scnScene.rootNode.addChildNode(rock)
                }
                continue
            }
            if let model = RoboticsHeroAssets.loadObstacle(
                named: key, targetSize: longSide * 1.15) {
                model.position = SCNVector3(oX, ttY + 0.02, oZ)
                scnScene.rootNode.addChildNode(model)
                continue
            }

            let baseH: Float = 0.55
            let baseGeo = SCNBox(width: CGFloat(oW), height: CGFloat(baseH),
                                  length: CGFloat(oH), chamferRadius: 0.04)
            let baseMat = pbrMaterial(
                diffuse: UIColor(red: 0.26, green: 0.28, blue: 0.32, alpha: 1),
                metalness: 0.18, roughness: 0.72
            )
            baseGeo.materials = [baseMat]
            let baseNode = SCNNode(geometry: baseGeo)
            baseNode.position = SCNVector3(oX, obsBaseY + baseH * 0.5, oZ)
            baseNode.castsShadow = true
            scnScene.rootNode.addChildNode(baseNode)

            // Dark accent top cap
            let capH: Float = 0.08
            let capGeo = SCNBox(width: CGFloat(oW + 0.02), height: CGFloat(capH),
                                 length: CGFloat(oH + 0.02), chamferRadius: 0.03)
            let capMat = pbrMaterial(
                diffuse: UIColor(red: 0.14, green: 0.16, blue: 0.19, alpha: 1),
                metalness: 0.22, roughness: 0.52
            )
            capGeo.materials = [capMat]
            let capNode = SCNNode(geometry: capGeo)
            capNode.position = SCNVector3(oX, obsBaseY + baseH + capH * 0.5, oZ)
            capNode.castsShadow = true
            scnScene.rootNode.addChildNode(capNode)

            // Metallic shelf stripe
            let stripeH: Float = 0.025
            let stripeGeo = SCNBox(width: CGFloat(oW + 0.03), height: CGFloat(stripeH),
                                    length: CGFloat(oH + 0.03), chamferRadius: 0.01)
            let stripeMat = pbrMaterial(
                diffuse: UIColor(red: 0.62, green: 0.65, blue: 0.70, alpha: 1),
                metalness: 0.38, roughness: 0.42
            )
            stripeGeo.materials = [stripeMat]
            let stripeNode = SCNNode(geometry: stripeGeo)
            stripeNode.position = SCNVector3(oX, obsBaseY + baseH * 0.52, oZ)
            stripeNode.castsShadow = false
            scnScene.rootNode.addChildNode(stripeNode)
        }

        // ---- Zone landmark models (bays, satellite dishes, launch structures) ----
        // A recognizable 3D structure at each zone's far edge, so the field reads
        // as real locations rather than abstract colored squares. Painted zone
        // markings on the mat remain for the drop target.
        let homeZoneIds: Set<String> = ["base_camp", "home_base"]
        for zone in world.zones {
            // The home zone stays CLEAR — it's where the rover parks; a landmark
            // there crowds and hides the hero.
            if homeZoneIds.contains(zone.id) { continue }
            let zW = Float(zone.rect.width)  * kScale
            let zH = Float(zone.rect.height) * kScale
            let zX = Float(zone.rect.x)      * kScale + zW * 0.5
            let kindKey: String
            let sizeFactor: Float
            switch zone.kind {
            case .deposit:   kindKey = "deposit";   sizeFactor = 0.95   // hangar fills the bay
            case .detection: kindKey = "detection"; sizeFactor = 0.72   // satellite dish
            case .goal:      kindKey = "goal";      sizeFactor = 0.60   // launch structure
            }
            let size = min(zW, zH) * sizeFactor
            guard let lm = RoboticsHeroAssets.loadZone(kind: kindKey, targetSize: size) else { continue }
            // North (far) edge of the zone, inset by half the model, so it frames
            // the drop area without blocking the approach from the south.
            let northZ = -(Float(zone.rect.y + zone.rect.height) * kScale) + size * 0.45
            lm.position = SCNVector3(zX, ttY + 0.02, northZ)
            scnScene.rootNode.addChildNode(lm)
        }

        // ---- Interactive mechanisms (levers, gates, platforms) ----
        // Each stores an animatable node in `mechanismNodes[id]`, moved to its
        // activated pose during playback on the exact activation frame.
        let warehouse = world.id == "field_warehouse"
        for mech in world.mechanisms {
            let (mx, mz) = worldXZ(mech.position)
            switch mech.kind {
            case .lever:
                mechanismNodes[mech.id] = Self.addLever(to: scnScene.rootNode,
                                                        x: mx, z: mz, baseY: ttY,
                                                        warehouse: warehouse)
            case .platform:
                mechanismNodes[mech.id] = Self.addPlatform(to: scnScene.rootNode,
                                                           x: mx, z: mz, baseY: ttY,
                                                           warehouse: warehouse)
            case .gate:
                // Draw the gate across the obstacle it unlocks (its physical bar).
                let bar = mech.unlocksObstacleId.flatMap { world.obstacle(id: $0) }
                mechanismNodes[mech.id] = Self.addGate(to: scnScene.rootNode,
                                                       rect: bar?.rect,
                                                       fallback: mech.position,
                                                       baseY: ttY,
                                                       warehouse: warehouse)
            case .launcher:
                mechanismNodes[mech.id] = Self.addLauncher(to: scnScene.rootNode,
                                                           x: mx, z: mz, baseY: ttY)
            case .excavator:
                mechanismNodes[mech.id] = Self.addExcavator(to: scnScene.rootNode,
                                                            x: mx, z: mz, baseY: ttY)
            }
            if let node = mechanismNodes[mech.id] {
                mechanismResetTransforms[mech.id] = node.position
            }
        }

        // ---- Items (pickable mission objects) ----
        // Prefer a bundled hero prop model (prop_<type>.dae) when present;
        // otherwise fall back to the procedural item geometry.
        for item in world.items {
            let (ix, iz) = worldXZ(item.position)
            let heroItem = RoboticsHeroAssets.loadItem(type: item.type)
            let node = heroItem
                ?? Self.makeItemNode(color: item.color, type: item.type, tableY: ttY)
            node.position = SCNVector3(ix, ttY + (heroItem != nil ? 0.02 : 0.12), iz)
            node.castsShadow = true
            scnScene.rootNode.addChildNode(node)
            itemNodes[item.id] = node
        }

        // ---- Robot (body + arm + gripper) ----
        // Prefer a bundled hero rover model (rover.usdz) when present; otherwise
        // fall back to the procedural robot. Both expose arm + gripper pivots so
        // playback drives articulation either way.
        let heroRobot = RoboticsHeroAssets.loadRobot()
        usingHeroRobot = (heroRobot != nil)
        let (robotNodes, arm, gripper) = heroRobot ?? Self.makeRobotNodes()
        robotNode   = robotNodes
        armNode     = arm
        gripperNode = gripper
        wheelNodes  = robotNodes.childNodes.filter { $0.name == "axle" }

        robotNode.scale = SCNVector3(robotScale, robotScale, robotScale)
        let homePose = world.resolvedHomePose
        let (hx, hz) = worldXZ(homePose.position)
        robotNode.position   = SCNVector3(hx, ttY + (usingHeroRobot ? 0.02 : 0.33), hz)
        robotNode.eulerAngles.y = headingToYRot(homePose.headingDegrees)
        scnScene.rootNode.addChildNode(robotNode)

        // ---- Camera: corner 3/4 hero angle with HDR pipeline ----
        cameraNode = SCNNode()
        let cam = SCNCamera()
        cam.fieldOfView = 46
        cam.zNear = 0.1
        cam.zFar  = 200

        // HDR pipeline — bloom, SSAO, exposure control
        cam.wantsHDR                     = true
        cam.bloomIntensity               = 0.18
        cam.bloomThreshold               = 0.72
        cam.bloomBlurRadius              = 6.0
        cam.screenSpaceAmbientOcclusionRadius    = 0.08
        cam.screenSpaceAmbientOcclusionIntensity = 0.60
        cam.screenSpaceAmbientOcclusionBias      = 0.03
        cam.screenSpaceAmbientOcclusionDepthThreshold = 0.8
        cam.wantsExposureAdaptation      = false
        cam.exposureOffset               = 0.10
        // No color fringe (it softens edges and hurts legibility on small models)
        cam.colorFringeStrength          = 0.0
        cam.colorFringeIntensity         = 0.0
        cam.vignettingPower              = 0.50
        cam.vignettingIntensity          = 0.28

        // Very mild depth of field — keep the whole field crisp, softening only
        // the far background. Deep focus (high fStop) so the mat reads sharp.
        cam.wantsDepthOfField = true
        cam.fStop             = 7.0
        cam.apertureBladeCount = 6

        cameraNode.camera = cam

        // Camera: centered 3/4 "hero" angle that fills the 4:3 frame.
        // Aim at the field centre and orbit to a corner at a comfortable elevation,
        // rotated so the square field's diagonal spans the frame width.
        let fieldCX = wW * 0.5
        let fieldCZ = -wH * 0.5
        let diag = sqrt(wW * wW + wH * wH)

        let target = SCNVector3(fieldCX, ttY + 0.12, fieldCZ)

        let azimuth:   Float = .pi * 0.17   // ~31° off the south axis
        let elevation: Float = .pi * 0.27   // ~49° above the mat
        let radius:    Float = diag * 0.86

        let camX = fieldCX + radius * cos(elevation) * sin(azimuth)
        let camY = ttY + radius * sin(elevation)
        let camZ = fieldCZ + radius * cos(elevation) * cos(azimuth)
        cameraNode.position = SCNVector3(camX, camY, camZ)

        let dx = target.x - camX
        let dy = target.y - camY
        let dz = target.z - camZ
        let camToTarget = sqrt(dx * dx + dy * dy + dz * dz)
        cam.focusDistance = CGFloat(camToTarget)

        let pitchAngle = atan2(dy, sqrt(dx * dx + dz * dz))
        let yawAngle   = atan2(dx, dz) + .pi
        cameraNode.eulerAngles = SCNVector3(pitchAngle, yawAngle, 0)

        scnScene.rootNode.addChildNode(cameraNode)
    }

    // MARK: - Environment map

    /// Builds a 6-face cube-map from a single gradient image (faces share same sky→ground gradient).
    private static func makeEnvironmentMap() -> UIImage {
        let size: CGFloat = 128
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: size, height: size))
        return renderer.image { ctx in
            let c = ctx.cgContext
            // Top half: warm soft cream (key light direction)
            // Bottom half: cool slate (reflected ground)
            let stops: [(CGFloat, UIColor)] = [
                (0.00, UIColor(red: 0.92, green: 0.88, blue: 0.82, alpha: 1)),
                (0.30, UIColor(red: 0.70, green: 0.72, blue: 0.80, alpha: 1)),
                (0.60, UIColor(red: 0.28, green: 0.30, blue: 0.40, alpha: 1)),
                (1.00, UIColor(red: 0.10, green: 0.10, blue: 0.16, alpha: 1))
            ]
            let colors = stops.map { $0.1.cgColor } as CFArray
            let locs   = stops.map { $0.0 } as [CGFloat]
            let space  = CGColorSpaceCreateDeviceRGB()
            let grad   = CGGradient(colorsSpace: space, colors: colors, locations: locs)!
            c.drawLinearGradient(grad,
                                  start: CGPoint(x: 0, y: 0),
                                  end:   CGPoint(x: 0, y: size),
                                  options: [])
        }
    }

    // MARK: - Lighting

    private static func addLighting(to root: SCNNode, wW: Float, wH: Float, ttY: Float) {
        // Ambient: very soft cool fill — environment map handles most of the fill,
        // so this just lifts the deepest shadows minimally.
        let ambNode = SCNNode(); let ambLight = SCNLight()
        ambLight.type      = .ambient
        ambLight.color     = UIColor(red: 0.18, green: 0.20, blue: 0.28, alpha: 1)
        ambLight.intensity = 250
        ambNode.light = ambLight
        root.addChildNode(ambNode)

        // Key: warm directional from upper-left-front (studio key position)
        // High shadow quality for soft, grounded shadows on the mat.
        let keyNode = SCNNode(); let keyLight = SCNLight()
        keyLight.type       = .directional
        keyLight.color      = UIColor(red: 1.0, green: 0.95, blue: 0.85, alpha: 1)
        keyLight.intensity  = 1600
        keyLight.castsShadow = true
        keyLight.shadowMode         = .deferred
        keyLight.shadowSampleCount  = 16
        keyLight.shadowRadius       = 4.0
        keyLight.shadowColor        = UIColor(white: 0, alpha: 0.35)
        keyLight.orthographicScale  = Double(max(wW, wH) * 0.85)
        keyNode.light = keyLight
        keyNode.eulerAngles = SCNVector3(-Float.pi / 3.4, Float.pi / 5.0, 0)
        keyNode.position    = SCNVector3(wW * 0.15, ttY + 6.5, -wH * 0.1)
        root.addChildNode(keyNode)

        // Fill: cool-blue from opposite side (rim fill, bounce feel)
        let fillNode = SCNNode(); let fillLight = SCNLight()
        fillLight.type      = .omni
        fillLight.color     = UIColor(red: 0.38, green: 0.52, blue: 0.86, alpha: 1)
        fillLight.intensity = 380
        fillNode.light = fillLight
        fillNode.position = SCNVector3(wW * 0.88, ttY + 3.8, -wH * 0.12)
        root.addChildNode(fillNode)

        // Rim: warm back-light separating robot from mat
        let rimNode = SCNNode(); let rimLight = SCNLight()
        rimLight.type      = .directional
        rimLight.color     = UIColor(red: 0.92, green: 0.82, blue: 0.58, alpha: 1)
        rimLight.intensity = 260
        rimNode.light = rimLight
        rimNode.eulerAngles = SCNVector3(Float.pi / 6, Float.pi * 0.88, 0)
        root.addChildNode(rimNode)

        // Top-down soft overhead fill (simulates stadium/arena ceiling wash)
        let topNode = SCNNode(); let topLight = SCNLight()
        topLight.type      = .directional
        topLight.color     = UIColor(red: 0.85, green: 0.86, blue: 0.90, alpha: 1)
        topLight.intensity = 300
        topNode.light = topLight
        topNode.eulerAngles = SCNVector3(-Float.pi / 2, 0, 0)
        root.addChildNode(topNode)
    }

    // MARK: - Border walls with wood grain

    private static func addBorderWalls(to root: SCNNode, wW: Float, wH: Float,
                                       matY: Float, woodTexture: UIImage) {
        let wallH: Float = 0.20
        let wallT: Float = 0.07
        let wallY = matY + wallH * 0.5

        let wallMat: SCNMaterial = {
            let m = pbrMaterial(diffuse: woodTexture, metalness: 0.0, roughness: 0.76)
            m.diffuse.wrapS = .repeat
            m.diffuse.wrapT = .repeat
            return m
        }()

        // Inner face (darker, shaded side facing field interior)
        let innerMat = pbrMaterial(
            diffuse: UIColor(red: 0.54, green: 0.44, blue: 0.30, alpha: 1),
            metalness: 0.0, roughness: 0.82
        )

        // Top face (worn top edge)
        let topMat = pbrMaterial(
            diffuse: UIColor(red: 0.72, green: 0.62, blue: 0.44, alpha: 1),
            metalness: 0.0, roughness: 0.70
        )

        let walls: [(cx: Float, cz: Float, wid: Float, dep: Float)] = [
            (wW * 0.5,         wallT * 0.5,        wW + wallT * 2, wallT),
            (wW * 0.5,        -wH - wallT * 0.5,   wW + wallT * 2, wallT),
            (-wallT * 0.5,    -wH * 0.5,            wallT, wH),
            (wW + wallT * 0.5, -wH * 0.5,           wallT, wH),
        ]

        for wall in walls {
            let geo = SCNBox(width: CGFloat(wall.wid), height: CGFloat(wallH),
                             length: CGFloat(wall.dep), chamferRadius: 0.008)
            // Per-face materials: [+x, -x, +y(top), -y(bot), +z, -z]
            // For a wall, we want: outer face = wood grain, inner face = darker, top = lighter
            // SCNBox face order: right, left, top, bottom, front, back
            geo.materials = [wallMat, innerMat, topMat, wallMat, wallMat, innerMat]
            let node = SCNNode(geometry: geo)
            node.position = SCNVector3(wall.cx, wallY, wall.cz)
            node.castsShadow = true
            root.addChildNode(node)
        }

        // Corner block caps (fills the gaps where North/South and East/West walls meet)
        let capMat = pbrMaterial(
            diffuse: UIColor(red: 0.46, green: 0.38, blue: 0.26, alpha: 1),
            metalness: 0.02, roughness: 0.80
        )
        for (cx, cz) in [(-wallT * 0.5, wallT * 0.5),
                          (wW + wallT * 0.5, wallT * 0.5),
                          (-wallT * 0.5, -wH - wallT * 0.5),
                          (wW + wallT * 0.5, -wH - wallT * 0.5)] as [(Float, Float)] {
            let cGeo = SCNBox(width: CGFloat(wallT), height: CGFloat(wallH),
                              length: CGFloat(wallT), chamferRadius: 0.008)
            cGeo.materials = [capMat]
            let cNode = SCNNode(geometry: cGeo)
            cNode.position = SCNVector3(cx, wallY, cz)
            root.addChildNode(cNode)
        }
    }

    // MARK: - Printed mat texture (2048²)

    /// Generates the full-field printed mat as a high-resolution texture.
    /// ALL zones, colored regions, lines, goal graphics, labels, grain, and
    /// the decorative border are rendered into this single image.
    /// The image UV-maps 1:1 to the mat SCNBox top face.
    private static func makePrintedMatTexture(world: FieldWorld) -> UIImage {
        let texW: CGFloat = 2048
        let texH: CGFloat = CGFloat(texW * CGFloat(world.heightCm / world.widthCm))

        // Conversion: field cm → texture pixels
        let scaleX = texW / CGFloat(world.widthCm)
        let scaleY = texH / CGFloat(world.heightCm)

        // field cm rect → texture CGRect (field +y = top of image)
        func fieldToTex(_ rect: FieldRect) -> CGRect {
            let px = CGFloat(rect.x) * scaleX
            let py = texH - (CGFloat(rect.y) * scaleY + CGFloat(rect.height) * scaleY)
            return CGRect(x: px, y: py,
                          width:  CGFloat(rect.width)  * scaleX,
                          height: CGFloat(rect.height) * scaleY)
        }
        func fieldPtToTex(_ p: Vec2) -> CGPoint {
            CGPoint(x: CGFloat(p.x) * scaleX,
                    y: texH - CGFloat(p.y) * scaleY)
        }

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: texW, height: texH))
        return renderer.image { rCtx in
            let ctx = rCtx.cgContext

            // 1. Base mat color — themed per field: Mars sand for the arena,
            // warm light gray for the warehouse, a cool game-board for challenges.
            let isChallenge = world.id.hasPrefix("challenge")
            let baseMat: UIColor = {
                if isChallenge { return UIColor(red: 0.82, green: 0.87, blue: 0.90, alpha: 1) }
                return world.id == "field_arena"
                    ? UIColor(red: 0.87, green: 0.74, blue: 0.58, alpha: 1)
                    : UIColor(red: 0.90, green: 0.89, blue: 0.86, alpha: 1)
            }()
            baseMat.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: texW, height: texH))

            // Challenge fields read as a clean tile board: checkerboard tiles.
            if isChallenge {
                let cols = Int((world.widthCm  / 30.0).rounded())
                let rows = Int((world.heightCm / 30.0).rounded())
                let tw = texW / CGFloat(cols)
                let th = texH / CGFloat(rows)
                for r in 0..<rows {
                    for c in 0..<cols where (r + c) % 2 == 1 {
                        UIColor(red: 0.75, green: 0.82, blue: 0.86, alpha: 1).setFill()
                        ctx.fill(CGRect(x: CGFloat(c) * tw, y: CGFloat(r) * th, width: tw, height: th))
                    }
                }
            }

            // Subtle noise grain (alternating light/dark specks)
            Self.drawGrainNoise(ctx: ctx, rect: CGRect(x: 0, y: 0, width: texW, height: texH))

            // Soft inner radial shadow (mat reads as lit from above, darker at edges)
            Self.drawRadialVignette(ctx: ctx, size: CGSize(width: texW, height: texH),
                                    alpha: 0.10)

            // 2. Decorative border frame (double-line printed ring just inside the mat edge)
            Self.drawMatBorderFrame(ctx: ctx, texW: texW, texH: texH)

            // 3. Colored regions (flat printed color fills, soft rounded)
            for region in world.coloredRegions {
                let r = fieldToTex(region.rect)
                let col = filmicColor(region.color)
                // Semi-transparent fill with a linear gradient for depth
                Self.drawPrintedZone(ctx: ctx, rect: r, color: col,
                                     alpha: 0.55, cornerRadius: 4)
            }

            // 4. Deposit zones (strong printed color with outline ring + hatch)
            for zone in world.zones {
                let r = fieldToTex(zone.rect)
                let col = filmicColor(zone.color)
                switch zone.kind {
                case .deposit:
                    Self.drawDepositZone(ctx: ctx, rect: r, color: col)
                case .detection:
                    Self.drawDetectionPad(ctx: ctx, rect: r, color: col)
                case .goal:
                    Self.drawGoalZone(ctx: ctx, rect: r, color: col)
                }
            }

            // 5. Field lines (painted strips in white/cream, with worn-edge feel)
            for line in world.lines {
                guard line.points.count >= 2 else { continue }
                let lineW = max(CGFloat(line.width) * scaleX, 3.0)
                ctx.setLineWidth(lineW)
                ctx.setLineCap(.round)
                ctx.setLineJoin(.round)
                // Outer shadow stroke
                ctx.setStrokeColor(UIColor(white: 0, alpha: 0.18).cgColor)
                ctx.setLineWidth(lineW + 3)
                Self.strokePolyline(ctx: ctx, points: line.points.map { fieldPtToTex($0) })
                // Main white line
                ctx.setStrokeColor(UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 0.96).cgColor)
                ctx.setLineWidth(lineW)
                Self.strokePolyline(ctx: ctx, points: line.points.map { fieldPtToTex($0) })
            }

            // 6. Grid guide lines — every 30 cm. Bold on challenge boards so
            // tiles are clearly countable; very faint elsewhere.
            let cellW = texW / CGFloat(world.widthCm  / 30.0)
            let cellH = texH / CGFloat(world.heightCm / 30.0)
            ctx.setStrokeColor(isChallenge
                ? UIColor(red: 0.30, green: 0.42, blue: 0.52, alpha: 0.28).cgColor
                : UIColor(white: 0, alpha: 0.055).cgColor)
            ctx.setLineWidth(isChallenge ? 2.2 : 0.8)
            var gx: CGFloat = 0
            while gx <= texW { ctx.move(to: CGPoint(x: gx, y: 0))
                ctx.addLine(to: CGPoint(x: gx, y: texH)); gx += cellW }
            var gy: CGFloat = 0
            while gy <= texH { ctx.move(to: CGPoint(x: 0, y: gy))
                ctx.addLine(to: CGPoint(x: texW, y: gy)); gy += cellH }
            ctx.strokePath()

            // 7. Zone labels — every zone gets its NAME printed large, so the
            // field reads like a map ("LAUNCH PAD", "BASE CAMP", "BAY ALPHA"…).
            // Skipped on challenge boards (a single goal tile stays clean).
            let labelFont = UIFont.systemFont(ofSize: 34, weight: .bold)
            for zone in world.zones where !isChallenge {
                let r = fieldToTex(zone.rect)
                let label = zone.id.replacingOccurrences(of: "_", with: " ").uppercased()
                let textColor = filmicColorDark(zone.color ?? "gray").withAlphaComponent(0.72)
                // Draw in the SOUTH half of the zone so the landmark model at the
                // north edge doesn't cover the name.
                let labelRect = CGRect(x: r.minX, y: r.midY, width: r.width, height: r.height * 0.5)
                Self.drawCenteredLabel(ctx: ctx, text: label, in: labelRect,
                                       font: labelFont, color: textColor)
            }
        }
    }

    // MARK: - Texture drawing helpers

    private static func drawGrainNoise(ctx: CGContext, rect: CGRect) {
        // Draws a subtle noise overlay to break up the flat mat base color.
        // Uses deterministic pseudo-random positions for repeatable result.
        var seed: UInt64 = 0x517CC1B727220A95
        func nextFloat() -> CGFloat {
            seed = seed &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat(seed >> 33) / CGFloat(1 << 31)
        }
        let count = 18000
        for _ in 0..<count {
            let x = nextFloat() * rect.width
            let y = nextFloat() * rect.height
            let bright = nextFloat() > 0.5
            let alpha: CGFloat = 0.04 + nextFloat() * 0.06
            let col = bright ? UIColor(white: 1.0, alpha: alpha) : UIColor(white: 0.0, alpha: alpha * 0.7)
            col.setFill()
            ctx.fillEllipse(in: CGRect(x: x, y: y, width: 1.2, height: 1.2))
        }
    }

    private static func drawRadialVignette(ctx: CGContext, size: CGSize, alpha: CGFloat) {
        let centre = CGPoint(x: size.width * 0.5, y: size.height * 0.5)
        let radius = max(size.width, size.height) * 0.72
        let colors = [UIColor(white: 0, alpha: 0).cgColor,
                      UIColor(white: 0, alpha: alpha).cgColor] as CFArray
        let space  = CGColorSpaceCreateDeviceRGB()
        guard let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0.4, 1.0]) else { return }
        ctx.drawRadialGradient(grad, startCenter: centre, startRadius: 0,
                               endCenter: centre, endRadius: radius, options: [.drawsAfterEndLocation])
    }

    private static func drawMatBorderFrame(ctx: CGContext, texW: CGFloat, texH: CGFloat) {
        let inset1: CGFloat = 14
        let inset2: CGFloat = 24
        ctx.setStrokeColor(UIColor(white: 0, alpha: 0.18).cgColor)
        ctx.setLineWidth(3.5)
        ctx.stroke(CGRect(x: inset1, y: inset1, width: texW - inset1 * 2, height: texH - inset1 * 2))
        ctx.setStrokeColor(UIColor(white: 0, alpha: 0.10).cgColor)
        ctx.setLineWidth(1.5)
        ctx.stroke(CGRect(x: inset2, y: inset2, width: texW - inset2 * 2, height: texH - inset2 * 2))
    }

    private static func drawPrintedZone(ctx: CGContext, rect: CGRect, color: UIColor,
                                        alpha: CGFloat, cornerRadius: CGFloat) {
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
        ctx.addPath(path.cgPath)
        color.withAlphaComponent(alpha).setFill()
        ctx.fillPath()
    }

    private static func drawDepositZone(ctx: CGContext, rect: CGRect, color: UIColor) {
        // Soft fill gradient (lighter centre, darker edge) — printed-on feel
        let innerColor = color.lightened(by: 0.12).withAlphaComponent(0.72)
        let outerColor = color.darkened(by: 0.08).withAlphaComponent(0.82)

        let path = UIBezierPath(roundedRect: rect, cornerRadius: 6)
        ctx.saveGState()
        ctx.addPath(path.cgPath)
        ctx.clip()

        // Radial gradient fill
        let centre = CGPoint(x: rect.midX, y: rect.midY)
        let radius = max(rect.width, rect.height) * 0.72
        let colors = [innerColor.cgColor, outerColor.cgColor] as CFArray
        let space  = CGColorSpaceCreateDeviceRGB()
        if let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1]) {
            ctx.drawRadialGradient(grad, startCenter: centre, startRadius: 0,
                                   endCenter: centre, endRadius: radius, options: [.drawsAfterEndLocation])
        }
        ctx.restoreGState()

        // Printed outline ring (two strokes — outer dark, inner lighter)
        ctx.addPath(path.cgPath)
        ctx.setStrokeColor(color.darkened(by: 0.25).withAlphaComponent(0.85).cgColor)
        ctx.setLineWidth(4.5)
        ctx.strokePath()

        // Inner ring (slightly inset)
        let innerInset = rect.insetBy(dx: 8, dy: 8)
        let innerPath = UIBezierPath(roundedRect: innerInset, cornerRadius: 4)
        ctx.addPath(innerPath.cgPath)
        ctx.setStrokeColor(color.darkened(by: 0.15).withAlphaComponent(0.40).cgColor)
        ctx.setLineWidth(2.0)
        ctx.strokePath()

        // Corner registration marks
        let cmSize: CGFloat = 14
        let cmInset: CGFloat = 10
        let cmColor = color.darkened(by: 0.30).withAlphaComponent(0.60)
        ctx.setStrokeColor(cmColor.cgColor)
        ctx.setLineWidth(2.0)
        for (cx, cy, flipX, flipY) in [
            (rect.minX + cmInset, rect.minY + cmInset, false, false),
            (rect.maxX - cmInset, rect.minY + cmInset, true,  false),
            (rect.minX + cmInset, rect.maxY - cmInset, false, true ),
            (rect.maxX - cmInset, rect.maxY - cmInset, true,  true )
        ] as [(CGFloat, CGFloat, Bool, Bool)] {
            let xSign: CGFloat = flipX ? -1 : 1
            let ySign: CGFloat = flipY ? -1 : 1
            ctx.move(to: CGPoint(x: cx, y: cy + ySign * cmSize))
            ctx.addLine(to: CGPoint(x: cx, y: cy))
            ctx.addLine(to: CGPoint(x: cx + xSign * cmSize, y: cy))
            ctx.strokePath()
        }
    }

    private static func drawDetectionPad(ctx: CGContext, rect: CGRect, color: UIColor) {
        // Calm labelled pad: soft teal fill + dashed border. The 3D satellite
        // dish landmark carries the theme; the pad is just the drive target.
        let padColor = UIColor(red: 0.12, green: 0.62, blue: 0.70, alpha: 1)
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 8)
        ctx.addPath(path.cgPath)
        ctx.setFillColor(padColor.withAlphaComponent(0.22).cgColor)
        ctx.fillPath()
        let border = UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 8)
        border.setLineDash([12, 8], count: 2, phase: 0)
        ctx.addPath(border.cgPath)
        ctx.setStrokeColor(padColor.withAlphaComponent(0.85).cgColor)
        ctx.setLineWidth(4.0)
        ctx.strokePath()
    }

    private static func drawGoalZone(ctx: CGContext, rect: CGRect, color: UIColor) {
        // Calm labelled pad: soft amber fill + solid border (no bullseye clutter —
        // the 3D launch structure marks the spot).
        let padColor = UIColor(red: 0.90, green: 0.68, blue: 0.16, alpha: 1)
        let path = UIBezierPath(roundedRect: rect.insetBy(dx: 4, dy: 4), cornerRadius: 8)
        ctx.addPath(path.cgPath)
        ctx.setFillColor(padColor.withAlphaComponent(0.26).cgColor)
        ctx.fillPath()
        ctx.addPath(path.cgPath)
        ctx.setStrokeColor(padColor.withAlphaComponent(0.85).cgColor)
        ctx.setLineWidth(4.5)
        ctx.strokePath()
    }

    private static func strokePolyline(ctx: CGContext, points: [CGPoint]) {
        guard points.count >= 2 else { return }
        ctx.beginPath()
        ctx.move(to: points[0])
        for p in points.dropFirst() { ctx.addLine(to: p) }
        ctx.strokePath()
    }

    private static func drawCenteredLabel(ctx: CGContext, text: String, in rect: CGRect,
                                           font: UIFont, color: UIColor) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let str = text as NSString
        let size = str.size(withAttributes: attrs)
        if size.width > rect.width - 8 || size.height > rect.height - 4 { return }
        let tx = rect.midX - size.width  * 0.5
        let ty = rect.midY - size.height * 0.5
        str.draw(at: CGPoint(x: tx, y: ty), withAttributes: attrs)
    }

    // MARK: - Wood grain texture (procedural)

    private static func makeWoodGrainTexture(width: Int, height: Int) -> UIImage {
        let w = CGFloat(width); let h = CGFloat(height)
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: w, height: h))
        return renderer.image { rCtx in
            let ctx = rCtx.cgContext

            // Base wood color: warm medium brown
            UIColor(red: 0.58, green: 0.44, blue: 0.28, alpha: 1).setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))

            // Draw wood grain lines: horizontal (along the length of the wall)
            // Vary color slightly per grain band
            var seed2: UInt64 = 0xDEADBEEFCAFEBABE
            func nextF2() -> CGFloat {
                seed2 = seed2 &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat(seed2 >> 33) / CGFloat(1 << 31)
            }

            var y: CGFloat = 0
            while y < h {
                let grainH = 1.5 + nextF2() * 6.0
                let light  = nextF2() > 0.5
                let alpha  = 0.06 + nextF2() * 0.14
                let col    = light
                    ? UIColor(white: 1.0, alpha: alpha)
                    : UIColor(white: 0.0, alpha: alpha * 0.8)
                col.setFill()
                ctx.fill(CGRect(x: 0, y: y, width: w, height: grainH))
                y += grainH + nextF2() * 3.0
            }

            // A few darker knot-like vertical clusters
            for _ in 0..<3 {
                let kx = nextF2() * w
                let ky = nextF2() * h
                let kr = 8 + nextF2() * 20
                let kAlpha = 0.10 + nextF2() * 0.12
                UIColor(white: 0, alpha: kAlpha).setFill()
                ctx.fillEllipse(in: CGRect(x: kx - kr, y: ky - kr * 0.4,
                                           width: kr * 2, height: kr * 0.8))
            }

            // Subtle varnish gloss (very faint radial highlight at top-left)
            let gloss = CGRect(x: 0, y: 0, width: w * 0.5, height: h * 0.4)
            UIColor(white: 1.0, alpha: 0.08).setFill()
            ctx.fillEllipse(in: gloss)
        }
    }

    // MARK: - Background gradient

    private static func makeGradientBackground() -> UIImage {
        let size = CGSize(width: 256, height: 256)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { rCtx in
            let ctx = rCtx.cgContext
            let colors = [
                UIColor(red: 0.06, green: 0.08, blue: 0.15, alpha: 1).cgColor,
                UIColor(red: 0.02, green: 0.03, blue: 0.08, alpha: 1).cgColor
            ] as CFArray
            let grad = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                   colors: colors, locations: [0, 1])!
            ctx.drawLinearGradient(grad,
                                    start: CGPoint(x: 0, y: 0),
                                    end:   CGPoint(x: 0, y: size.height),
                                    options: [])
        }
    }

    // MARK: - Obstacle model key

    /// Maps a field-obstacle id to a bundled obstacle model key. Warehouse ids
    /// (shelf/rack) fall through to their own name → no model → procedural box.
    private static func obstacleKey(for id: String) -> String {
        let l = id.lowercased()
        if l.contains("crater")  { return "crater" }
        if l.contains("scatter") { return "scatter" }
        if l.contains("boulder") || l.contains("rock") { return "boulder" }
        return id
    }

    // MARK: - Mechanism geometry
    //
    // Each returns the node that MOVES on activation (stored in mechanismNodes):
    //   lever    → the pivoting handle (rotates/tips)
    //   platform → the top slab (rises)
    //   gate     → the barrier (drops into the ground, opening the lane)

    /// A friendly warning-striped lever: a fixed base + a red handle that tips.
    /// In the warehouse it reads as a yellow-and-black industrial release lever
    /// standing beside a short roller chute (the crate rolls out of it on release).
    private static func addLever(to root: SCNNode, x: Float, z: Float, baseY: Float,
                                 warehouse: Bool = false) -> SCNNode {
        // Fixed housing
        let houseColor = warehouse
            ? UIColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1)   // black industrial base
            : UIColor(red: 0.30, green: 0.32, blue: 0.36, alpha: 1)
        let houseGeo = SCNBox(width: 0.34, height: 0.14, length: 0.34, chamferRadius: 0.04)
        houseGeo.materials = [pbrMaterial(diffuse: houseColor, metalness: 0.4, roughness: 0.5)]
        let house = SCNNode(geometry: houseGeo)
        house.position = SCNVector3(x, baseY + 0.07, z)
        house.castsShadow = true
        root.addChildNode(house)

        if warehouse {
            // A short roller chute beside the lever: a sloped steel bed with roller
            // cylinders, the lane the freed crate rolls down. Purely decorative.
            let chute = SCNNode()
            let bedGeo = SCNBox(width: 0.30, height: 0.03, length: 0.46, chamferRadius: 0.01)
            bedGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.42, green: 0.44, blue: 0.48, alpha: 1),
                                            metalness: 0.7, roughness: 0.35)]
            let bed = SCNNode(geometry: bedGeo)
            bed.eulerAngles = SCNVector3(0.32, 0, 0)      // tilt down toward the crate
            chute.addChildNode(bed)
            for i in 0..<4 {
                let rollGeo = SCNCylinder(radius: 0.025, height: 0.30)
                rollGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.80, green: 0.82, blue: 0.86, alpha: 1),
                                                 metalness: 0.85, roughness: 0.25)]
                let roll = SCNNode(geometry: rollGeo)
                roll.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
                roll.position = SCNVector3(0, 0.05 + Float(i) * 0.028, -0.16 + Float(i) * 0.11)
                chute.addChildNode(roll)
            }
            chute.position = SCNVector3(x, baseY + 0.10, z + 0.42)
            root.addChildNode(chute)
        }

        // Pivot at the top of the housing; handle points up, tips forward on activation.
        let pivot = SCNNode()
        pivot.position = SCNVector3(x, baseY + 0.14, z)
        root.addChildNode(pivot)
        let handleColor = warehouse
            ? UIColor(red: 0.96, green: 0.76, blue: 0.09, alpha: 1)   // safety yellow
            : UIColor(red: 0.86, green: 0.24, blue: 0.20, alpha: 1)
        let handleGeo = SCNBox(width: 0.06, height: 0.42, length: 0.06, chamferRadius: 0.02)
        handleGeo.materials = [pbrMaterial(diffuse: handleColor, metalness: 0.2, roughness: 0.45)]
        let handle = SCNNode(geometry: handleGeo)
        handle.position = SCNVector3(0, 0.21, 0)   // sits above the pivot
        handle.castsShadow = true
        pivot.addChildNode(handle)
        let knobColor = warehouse
            ? UIColor(red: 0.88, green: 0.20, blue: 0.16, alpha: 1)   // red release knob
            : UIColor(red: 0.95, green: 0.78, blue: 0.20, alpha: 1)
        let knobGeo = SCNSphere(radius: 0.06)
        knobGeo.materials = [pbrMaterial(diffuse: knobColor, metalness: 0.1, roughness: 0.3,
                                         emission: UIColor(red: 0.3, green: 0.16, blue: 0.0, alpha: 1))]
        let knob = SCNNode(geometry: knobGeo)
        knob.position = SCNVector3(0, 0.44, 0)
        pivot.addChildNode(knob)
        return pivot   // rotating this tips the whole handle
    }

    /// A platform: fixed posts + a top slab that rises on activation. In the
    /// warehouse it reads as a dock-leveler: a ribbed steel deck plate with a
    /// yellow-and-black striped safety lip that rises on its posts.
    private static func addPlatform(to root: SCNNode, x: Float, z: Float, baseY: Float,
                                    warehouse: Bool = false) -> SCNNode {
        let postMat = pbrMaterial(diffuse: UIColor(red: 0.28, green: 0.30, blue: 0.34, alpha: 1),
                                  metalness: 0.4, roughness: 0.5)
        for (dx, dz) in [(-0.26, -0.26), (0.26, -0.26), (-0.26, 0.26), (0.26, 0.26)] as [(Float, Float)] {
            let postGeo = SCNBox(width: 0.06, height: 0.18, length: 0.06, chamferRadius: 0.01)
            postGeo.materials = [postMat]
            let post = SCNNode(geometry: postGeo)
            post.position = SCNVector3(x + dx, baseY + 0.09, z + dz)
            root.addChildNode(post)
        }
        let slabColor = warehouse
            ? UIColor(red: 0.50, green: 0.52, blue: 0.56, alpha: 1)   // brushed steel deck
            : UIColor(red: 0.24, green: 0.52, blue: 0.86, alpha: 1)
        let slabGeo = SCNBox(width: 0.66, height: 0.08, length: 0.66, chamferRadius: 0.03)
        slabGeo.materials = [pbrMaterial(diffuse: slabColor,
                                         metalness: warehouse ? 0.8 : 0.2,
                                         roughness: warehouse ? 0.3 : 0.4)]
        let slab = SCNNode(geometry: slabGeo)
        slab.position = SCNVector3(x, baseY + 0.20, z)
        slab.castsShadow = true
        root.addChildNode(slab)

        if warehouse {
            // Ribbed deck: raised steel treads across the plate.
            let treadMat = pbrMaterial(diffuse: UIColor(red: 0.58, green: 0.60, blue: 0.64, alpha: 1),
                                       metalness: 0.85, roughness: 0.25)
            for i in 0..<5 {
                let ribGeo = SCNBox(width: 0.60, height: 0.02, length: 0.03, chamferRadius: 0.005)
                ribGeo.materials = [treadMat]
                let rib = SCNNode(geometry: ribGeo)
                rib.position = SCNVector3(0, 0.05, -0.24 + Float(i) * 0.12)
                slab.addChildNode(rib)
            }
            // Safety-yellow leading lip so the leveler edge reads clearly.
            let lipGeo = SCNBox(width: 0.66, height: 0.05, length: 0.06, chamferRadius: 0.01)
            lipGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.96, green: 0.76, blue: 0.09, alpha: 1),
                                            metalness: 0.2, roughness: 0.5)]
            let lip = SCNNode(geometry: lipGeo)
            lip.position = SCNVector3(0, 0.02, 0.33)
            slab.addChildNode(lip)
        }
        return slab   // rising this = the platform lifts
    }

    /// A gate barrier across `rect` (the obstacle it locks). Drops into the mat
    /// on activation, opening the lane. In the warehouse it reads as a segmented
    /// roll-up bay door that lifts up on its side rails. Returns the barrier node.
    private static func addGate(to root: SCNNode, rect: FieldRect?, fallback: Vec2,
                                baseY: Float, warehouse: Bool = false) -> SCNNode {
        let cx: Float, cz: Float, wid: Float, dep: Float
        if let r = rect {
            wid = max(Float(r.width) * kScale, 0.2)
            dep = max(Float(r.height) * kScale, 0.2)
            cx = Float(r.x) * kScale + wid * 0.5
            cz = -(Float(r.y) * kScale + dep * 0.5)
        } else {
            cx = worldX(fallback.x); cz = worldZ(fallback.y); wid = 0.4; dep = 0.16
        }

        if warehouse {
            // Roll-up bay door: stacked corrugated slats between two side rails,
            // a safety-yellow kick strip along the bottom. Lifts up on activation.
            let span = max(wid, dep)                 // the door's width across the lane
            let runsAlongZ = dep > wid
            let barrier = SCNNode()
            barrier.position = SCNVector3(cx, baseY + 0.30, cz)
            let slatMat = pbrMaterial(diffuse: UIColor(red: 0.62, green: 0.64, blue: 0.68, alpha: 1),
                                      metalness: 0.75, roughness: 0.35)
            let slatThick = CGFloat(min(wid, dep) * 0.6)
            for i in 0..<5 {
                let slatGeo = SCNBox(width: CGFloat(span), height: 0.10, length: slatThick,
                                     chamferRadius: 0.015)
                slatGeo.materials = [slatMat]
                let slat = SCNNode(geometry: slatGeo)
                slat.position = SCNVector3(0, -0.24 + Float(i) * 0.12, 0)
                if runsAlongZ { slat.eulerAngles.y = .pi / 2 }
                slat.castsShadow = true
                barrier.addChildNode(slat)
            }
            // Yellow kick strip at the bottom slat.
            let kickGeo = SCNBox(width: CGFloat(span), height: 0.055, length: slatThick * 1.05,
                                 chamferRadius: 0.01)
            kickGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.96, green: 0.76, blue: 0.09, alpha: 1),
                                             metalness: 0.2, roughness: 0.5)]
            let kick = SCNNode(geometry: kickGeo)
            kick.position = SCNVector3(0, -0.29, 0)
            if runsAlongZ { kick.eulerAngles.y = .pi / 2 }
            barrier.addChildNode(kick)
            // Side rails the door slides up in.
            let railMat = pbrMaterial(diffuse: UIColor(red: 0.22, green: 0.23, blue: 0.26, alpha: 1),
                                      metalness: 0.5, roughness: 0.5)
            let half = span * 0.5
            for t in [-half, half] {
                let rg = SCNBox(width: 0.05, height: 0.66, length: 0.05, chamferRadius: 0.01)
                rg.materials = [railMat]
                let rail = SCNNode(geometry: rg)
                rail.position = runsAlongZ ? SCNVector3(0, -0.12, t) : SCNVector3(t, -0.12, 0)
                barrier.addChildNode(rail)
            }
            root.addChildNode(barrier)
            return barrier
        }

        let barrier = SCNNode()
        barrier.position = SCNVector3(cx, baseY + 0.18, cz)
        // Amber warning bars
        let barGeo = SCNBox(width: CGFloat(max(wid, dep)), height: 0.30,
                            length: CGFloat(min(wid, dep) * 0.5), chamferRadius: 0.02)
        barGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.92, green: 0.66, blue: 0.14, alpha: 1),
                                        metalness: 0.2, roughness: 0.45,
                                        emission: UIColor(red: 0.25, green: 0.16, blue: 0.0, alpha: 1))]
        let bar = SCNNode(geometry: barGeo)
        if dep > wid { bar.eulerAngles.y = .pi / 2 }
        bar.castsShadow = true
        barrier.addChildNode(bar)
        // Dark posts at each end
        let postMat = pbrMaterial(diffuse: UIColor(red: 0.20, green: 0.20, blue: 0.22, alpha: 1),
                                  metalness: 0.4, roughness: 0.5)
        let half = max(wid, dep) * 0.5
        let along: (Float) -> SCNVector3 = { t in
            dep > wid ? SCNVector3(0, -0.06, t) : SCNVector3(t, -0.06, 0)
        }
        for t in [-half, half] {
            let pg = SCNBox(width: 0.07, height: 0.42, length: 0.07, chamferRadius: 0.01)
            pg.materials = [postMat]
            let p = SCNNode(geometry: pg)
            p.position = along(t)
            barrier.addChildNode(p)
        }
        root.addChildNode(barrier)
        return barrier
    }

    /// A rocket on a launch pad with a red launch lever. The rocket is the
    /// animatable node — it blasts up off the pad when the lever is tripped.
    private static func addLauncher(to root: SCNNode, x: Float, z: Float, baseY: Float) -> SCNNode {
        // Fixed launch pad (a low ring the rocket stands on).
        let padGeo = SCNCylinder(radius: 0.34, height: 0.06)
        padGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.26, green: 0.28, blue: 0.32, alpha: 1),
                                        metalness: 0.5, roughness: 0.45)]
        let pad = SCNNode(geometry: padGeo)
        pad.position = SCNVector3(x, baseY + 0.03, z)
        pad.castsShadow = true
        root.addChildNode(pad)

        // Fixed launch lever off to one side (the thing the arm presses).
        let leverBase = SCNBox(width: 0.10, height: 0.16, length: 0.10, chamferRadius: 0.02)
        leverBase.materials = [pbrMaterial(diffuse: UIColor(red: 0.30, green: 0.32, blue: 0.36, alpha: 1),
                                           metalness: 0.4, roughness: 0.5)]
        let lb = SCNNode(geometry: leverBase)
        lb.position = SCNVector3(x + 0.34, baseY + 0.08, z + 0.20)
        root.addChildNode(lb)
        let leverArm = SCNBox(width: 0.05, height: 0.26, length: 0.05, chamferRadius: 0.02)
        leverArm.materials = [pbrMaterial(diffuse: UIColor(red: 0.88, green: 0.22, blue: 0.18, alpha: 1),
                                          metalness: 0.2, roughness: 0.4)]
        let la = SCNNode(geometry: leverArm)
        la.eulerAngles = SCNVector3(-0.5, 0, 0)
        la.position = SCNVector3(x + 0.34, baseY + 0.24, z + 0.20)
        root.addChildNode(la)

        // Rocket (animatable): body + nose cone + fins, standing on the pad.
        let rocket = SCNNode()
        let bodyGeo = SCNCylinder(radius: 0.11, height: 0.52)
        bodyGeo.materials = [pbrMaterial(diffuse: UIColor(white: 0.94, alpha: 1),
                                         metalness: 0.15, roughness: 0.35)]
        let body = SCNNode(geometry: bodyGeo)
        body.position = SCNVector3(0, 0.26, 0)
        rocket.addChildNode(body)
        let noseGeo = SCNCone(topRadius: 0, bottomRadius: 0.11, height: 0.20)
        noseGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.90, green: 0.26, blue: 0.22, alpha: 1),
                                         metalness: 0.15, roughness: 0.35)]
        let nose = SCNNode(geometry: noseGeo)
        nose.position = SCNVector3(0, 0.62, 0)
        rocket.addChildNode(nose)
        for ang in stride(from: Float(0), to: .pi * 2, by: .pi * 2 / 3) {
            let finGeo = SCNBox(width: 0.02, height: 0.16, length: 0.12, chamferRadius: 0.01)
            finGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.30, green: 0.34, blue: 0.42, alpha: 1),
                                            metalness: 0.3, roughness: 0.4)]
            let fin = SCNNode(geometry: finGeo)
            fin.position = SCNVector3(cos(ang) * 0.11, 0.09, sin(ang) * 0.11)
            fin.eulerAngles = SCNVector3(0, -ang, 0)
            rocket.addChildNode(fin)
        }
        rocket.position = SCNVector3(x, baseY + 0.06, z)
        rocket.castsShadow = true
        root.addChildNode(rocket)
        return rocket   // blasts upward on activation
    }

    /// A sample half-buried in a soil mound. The sample is the animatable node —
    /// it rises up out of the ground when the rover hooks and pulls it free.
    private static func addExcavator(to root: SCNNode, x: Float, z: Float, baseY: Float) -> SCNNode {
        // Fixed soil mound (a squashed brown dome).
        let moundGeo = SCNSphere(radius: 0.30)
        moundGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.42, green: 0.30, blue: 0.20, alpha: 1),
                                          metalness: 0.0, roughness: 0.95)]
        let mound = SCNNode(geometry: moundGeo)
        mound.scale = SCNVector3(1.0, 0.42, 1.0)
        mound.position = SCNVector3(x, baseY + 0.02, z)
        mound.castsShadow = true
        root.addChildNode(mound)

        // Sample (animatable): a green crystal core, mostly sunk into the mound.
        let sample = SCNNode()
        let coreGeo = SCNBox(width: 0.14, height: 0.24, length: 0.14, chamferRadius: 0.03)
        coreGeo.materials = [pbrMaterial(diffuse: UIColor(red: 0.30, green: 0.78, blue: 0.52, alpha: 1),
                                         metalness: 0.1, roughness: 0.35,
                                         emission: UIColor(red: 0.05, green: 0.20, blue: 0.12, alpha: 1))]
        let core = SCNNode(geometry: coreGeo)
        core.eulerAngles = SCNVector3(0.2, 0.5, 0.1)
        sample.addChildNode(core)
        // Start low: only the tip pokes above the mound.
        sample.position = SCNVector3(x, baseY + 0.02, z)
        sample.castsShadow = true
        root.addChildNode(sample)
        return sample   // rises out of the soil on activation
    }

    // MARK: - Item geometry

    private static func makeItemNode(color: String?, type: String?, tableY: Float) -> SCNNode {
        let col = filmicColor(color)
        let root = SCNNode()

        switch type?.lowercased() {
        case "crate":
            let bodyGeo = SCNBox(width: 0.20, height: 0.18, length: 0.20, chamferRadius: 0.025)
            let bodyMat = pbrMaterial(diffuse: col, metalness: 0.05, roughness: 0.70)
            bodyGeo.materials = [bodyMat]
            let body = SCNNode(geometry: bodyGeo)
            root.addChildNode(body)
            let lidGeo = SCNBox(width: 0.21, height: 0.025, length: 0.21, chamferRadius: 0.02)
            let lidMat = pbrMaterial(diffuse: col.darkened(by: 0.3),
                                     metalness: 0.10, roughness: 0.60)
            lidGeo.materials = [lidMat]
            let lid = SCNNode(geometry: lidGeo)
            lid.position = SCNVector3(0, 0.10, 0)
            root.addChildNode(lid)
            for (cx, cz) in [(-0.09, -0.09), (0.09, -0.09),
                               (-0.09,  0.09), (0.09,  0.09)] as [(Float, Float)] {
                let edgeGeo = SCNBox(width: 0.015, height: 0.19, length: 0.015, chamferRadius: 0.003)
                let edgeMat = pbrMaterial(
                    diffuse: UIColor(white: 0.78, alpha: 1),
                    metalness: 0.75, roughness: 0.28
                )
                edgeGeo.materials = [edgeMat]
                let edge = SCNNode(geometry: edgeGeo)
                edge.position = SCNVector3(cx, 0, cz)
                root.addChildNode(edge)
            }

        case "barrel":
            let bodyGeo = SCNCylinder(radius: 0.09, height: 0.22)
            let bodyMat = pbrMaterial(diffuse: col, metalness: 0.10, roughness: 0.55)
            bodyGeo.materials = [bodyMat]
            let body = SCNNode(geometry: bodyGeo)
            root.addChildNode(body)
            let rimMat = pbrMaterial(diffuse: UIColor(white: 0.72, alpha: 1),
                                     metalness: 0.55, roughness: 0.32)
            for yOff: Float in [-0.12, 0.12] {
                let capGeo = SCNCylinder(radius: 0.095, height: 0.025)
                capGeo.materials = [rimMat]
                let cap = SCNNode(geometry: capGeo)
                cap.position = SCNVector3(0, yOff, 0)
                root.addChildNode(cap)
            }
            let bandGeo = SCNCylinder(radius: 0.092, height: 0.025)
            let bandMat = pbrMaterial(diffuse: UIColor(white: 0.58, alpha: 1),
                                      metalness: 0.40, roughness: 0.38)
            bandGeo.materials = [bandMat]
            root.addChildNode(SCNNode(geometry: bandGeo))

        case "sample", "rock":
            let mainGeo = SCNSphere(radius: 0.11)
            mainGeo.segmentCount = 6
            let mainMat = pbrMaterial(diffuse: col, metalness: 0.0, roughness: 0.90)
            mainGeo.materials = [mainMat]
            let mainN = SCNNode(geometry: mainGeo)
            root.addChildNode(mainN)
            let bumpGeo = SCNSphere(radius: 0.065)
            bumpGeo.segmentCount = 5
            bumpGeo.materials = [mainMat]
            let bumpN = SCNNode(geometry: bumpGeo)
            bumpN.position = SCNVector3(0.06, 0.04, 0.04)
            root.addChildNode(bumpN)

        case "core":
            let capsGeo = SCNCapsule(capRadius: 0.075, height: 0.22)
            let capsMat = pbrMaterial(diffuse: col, metalness: 0.25, roughness: 0.45)
            capsGeo.materials = [capsMat]
            root.addChildNode(SCNNode(geometry: capsGeo))
            for yOff: Float in [-0.05, 0.05] {
                let ringGeo = SCNCylinder(radius: 0.08, height: 0.018)
                let ringMat = pbrMaterial(diffuse: UIColor(white: 0.85, alpha: 1),
                                          metalness: 0.80, roughness: 0.24)
                ringGeo.materials = [ringMat]
                let ringN = SCNNode(geometry: ringGeo)
                ringN.position = SCNVector3(0, yOff, 0)
                root.addChildNode(ringN)
            }

        case "cell":
            let cellGeo = SCNCylinder(radius: 0.065, height: 0.14)
            let cellMat = pbrMaterial(diffuse: col, metalness: 0.15, roughness: 0.50)
            cellGeo.materials = [cellMat]
            root.addChildNode(SCNNode(geometry: cellGeo))
            let topGeo = SCNCylinder(radius: 0.062, height: 0.010)
            let topMat = pbrMaterial(diffuse: col, metalness: 0.0, roughness: 0.20,
                                     emission: col.withAlphaComponent(0.8))
            topGeo.materials = [topMat]
            let topN = SCNNode(geometry: topGeo)
            topN.position = SCNVector3(0, 0.075, 0)
            root.addChildNode(topN)

        default:
            let geo = SCNSphere(radius: 0.10)
            let mat = pbrMaterial(diffuse: col, metalness: 0.0, roughness: 0.70)
            geo.materials = [mat]
            root.addChildNode(SCNNode(geometry: geo))
        }

        return root
    }

    // MARK: - Robot geometry

    private static func makeRobotNodes() -> (root: SCNNode, arm: SCNNode, gripper: SCNNode) {
        let root = SCNNode()

        // Chassis
        let bodyGeo = SCNBox(width: 0.60, height: 0.32, length: 0.58, chamferRadius: 0.07)
        let bodyMat = pbrMaterial(
            diffuse: UIColor(red: 0.14, green: 0.36, blue: 0.72, alpha: 1),
            metalness: 0.20, roughness: 0.52
        )
        bodyGeo.materials = [bodyMat]
        let bodyNode = SCNNode(geometry: bodyGeo)
        root.addChildNode(bodyNode)

        // Front panel
        let faceGeo = SCNBox(width: 0.54, height: 0.26, length: 0.025, chamferRadius: 0.03)
        let faceMat = pbrMaterial(
            diffuse: UIColor(red: 0.20, green: 0.48, blue: 0.88, alpha: 1),
            metalness: 0.30, roughness: 0.38
        )
        faceGeo.materials = [faceMat]
        let faceNode = SCNNode(geometry: faceGeo)
        faceNode.position = SCNVector3(0, 0.02, -0.305)
        root.addChildNode(faceNode)

        // Direction indicator nose wedge
        let noseGeo = SCNPyramid(width: 0.16, height: 0.12, length: 0.14)
        let noseMat = pbrMaterial(
            diffuse: UIColor(red: 1.0, green: 0.75, blue: 0.0, alpha: 1),
            metalness: 0.05, roughness: 0.38,
            emission: UIColor(red: 0.35, green: 0.25, blue: 0.0, alpha: 1)
        )
        noseGeo.materials = [noseMat]
        let noseNode = SCNNode(geometry: noseGeo)
        noseNode.eulerAngles = SCNVector3(Float.pi / 2, .pi, 0)
        noseNode.position    = SCNVector3(0, 0.05, -0.34)
        root.addChildNode(noseNode)

        // Eyes (cyan LEDs)
        for xOff: Float in [-0.12, 0.12] {
            let socketGeo = SCNCylinder(radius: 0.045, height: 0.020)
            let socketMat = pbrMaterial(diffuse: UIColor(white: 0.10, alpha: 1),
                                        metalness: 0.30, roughness: 0.50)
            socketGeo.materials = [socketMat]
            let socket = SCNNode(geometry: socketGeo)
            socket.eulerAngles = SCNVector3(Float.pi / 2, 0, 0)
            socket.position = SCNVector3(xOff, 0.08, -0.312)
            root.addChildNode(socket)

            let lensGeo = SCNSphere(radius: 0.033)
            let lensMat = pbrMaterial(
                diffuse: UIColor(red: 0.0, green: 0.92, blue: 0.95, alpha: 1),
                metalness: 0.0, roughness: 0.08,
                emission: UIColor(red: 0.0, green: 0.40, blue: 0.45, alpha: 1)
            )
            lensGeo.materials = [lensMat]
            let lens = SCNNode(geometry: lensGeo)
            lens.position = SCNVector3(xOff, 0.08, -0.330)
            root.addChildNode(lens)
        }

        // Treads / wheels — each mounted on a named "axle" node (identity rotation,
        // local X = the axle) so playback can roll them about X while driving.
        let treadH: Float = 0.55; let treadR: Float = 0.095
        for (wx, wz) in [(-0.34, -0.22), (0.34, -0.22),
                          (-0.34,  0.22), (0.34,  0.22)] as [(Float, Float)] {
            let axle = SCNNode()
            axle.name = "axle"
            axle.position = SCNVector3(wx, -0.10, wz)
            root.addChildNode(axle)

            let tGeo = SCNCylinder(radius: CGFloat(treadR), height: CGFloat(treadH))
            let tMat = pbrMaterial(diffuse: UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1),
                                   metalness: 0.05, roughness: 0.90)
            tGeo.materials = [tMat]
            let tNode = SCNNode(geometry: tGeo)
            tNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)   // drum axis → local X
            axle.addChildNode(tNode)

            // Tread lugs around the circumference so rotation is legible.
            let lugMat = pbrMaterial(diffuse: UIColor(white: 0.03, alpha: 1),
                                     metalness: 0.0, roughness: 1.0)
            for k in 0..<6 {
                let ang = Float(k) / 6.0 * 2 * .pi
                let lugGeo = SCNBox(width: CGFloat(treadH + 0.006), height: 0.014,
                                    length: 0.028, chamferRadius: 0.004)
                lugGeo.materials = [lugMat]
                let lug = SCNNode(geometry: lugGeo)
                lug.position    = SCNVector3(0, cos(ang) * (treadR + 0.006), sin(ang) * (treadR + 0.006))
                lug.eulerAngles = SCNVector3(ang, 0, 0)
                axle.addChildNode(lug)
            }

            let hubGeo = SCNCylinder(radius: CGFloat(treadR * 0.55), height: CGFloat(treadH + 0.01))
            let hubMat = pbrMaterial(diffuse: UIColor(red: 0.44, green: 0.44, blue: 0.48, alpha: 1),
                                     metalness: 0.70, roughness: 0.28)
            hubGeo.materials = [hubMat]
            let hubNode = SCNNode(geometry: hubGeo)
            hubNode.eulerAngles = SCNVector3(0, 0, Float.pi / 2)
            axle.addChildNode(hubNode)
        }

        // Tread rails
        for xSide: Float in [-0.34, 0.34] {
            let railGeo = SCNBox(width: 0.025, height: 0.065, length: CGFloat(treadH),
                                  chamferRadius: 0.005)
            let railMat = pbrMaterial(diffuse: UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1),
                                      metalness: 0.0, roughness: 0.88)
            railGeo.materials = [railMat]
            let railNode = SCNNode(geometry: railGeo)
            railNode.position = SCNVector3(xSide + (xSide > 0 ? 0.10 : -0.10), -0.10, 0)
            root.addChildNode(railNode)
        }

        // Roof sensor hump
        let roofGeo = SCNBox(width: 0.30, height: 0.08, length: 0.28, chamferRadius: 0.04)
        let roofMat = pbrMaterial(diffuse: UIColor(red: 0.18, green: 0.22, blue: 0.30, alpha: 1),
                                   metalness: 0.25, roughness: 0.48)
        roofGeo.materials = [roofMat]
        let roofNode = SCNNode(geometry: roofGeo)
        roofNode.position = SCNVector3(0, 0.20, 0.05)
        root.addChildNode(roofNode)

        // Arm pivot
        let armPivot = SCNNode()
        armPivot.position = SCNVector3(0, 0.17, -0.24)
        root.addChildNode(armPivot)

        let armGeo = SCNBox(width: 0.05, height: 0.055, length: 0.35, chamferRadius: 0.01)
        let armMat = pbrMaterial(diffuse: UIColor(red: 0.62, green: 0.64, blue: 0.68, alpha: 1),
                                  metalness: 0.60, roughness: 0.32)
        armGeo.materials = [armMat]
        let armSeg = SCNNode(geometry: armGeo)
        armSeg.position = SCNVector3(0, 0, -0.175)
        armPivot.addChildNode(armSeg)

        let elbowGeo = SCNSphere(radius: 0.04)
        let elbowMat = pbrMaterial(diffuse: UIColor(red: 0.40, green: 0.42, blue: 0.45, alpha: 1),
                                    metalness: 0.75, roughness: 0.22)
        elbowGeo.materials = [elbowMat]
        let elbowNode = SCNNode(geometry: elbowGeo)
        elbowNode.position = SCNVector3(0, 0, -0.35)
        armPivot.addChildNode(elbowNode)

        let gripPivot = SCNNode()
        gripPivot.position = SCNVector3(0, 0, -0.35)
        armPivot.addChildNode(gripPivot)

        func makeJaw() -> SCNNode {
            let g = SCNBox(width: 0.035, height: 0.040, length: 0.13, chamferRadius: 0.008)
            let m = pbrMaterial(diffuse: UIColor(red: 0.78, green: 0.80, blue: 0.82, alpha: 1),
                                metalness: 0.65, roughness: 0.26)
            g.materials = [m]
            return SCNNode(geometry: g)
        }

        let jawL = makeJaw(); jawL.position = SCNVector3(-0.06, 0, -0.065)
        let jawR = makeJaw(); jawR.position = SCNVector3( 0.06, 0, -0.065)
        gripPivot.addChildNode(jawL)
        gripPivot.addChildNode(jawR)

        return (root, armPivot, gripPivot)
    }

    // MARK: - Playback

    /// Animate the robot through `snapshots` like a real FLL robot: it **drives**
    /// in a straight line (time scaled to distance) and **pivots in place** (time
    /// scaled to angle) between keyframes, rather than snapping to each pose. Arm
    /// articulation, gripper, and drive-wheel spin all run in lock-step with each
    /// frame's own duration.
    ///
    /// `teleportFrames` are frame indices produced by a genuine `returnHome()` —
    /// the only case where the rover legitimately "jumps" (a human lifting it back
    /// to base). Those fade out/in instead of driving through the field.
    ///
    /// `onFrameIndex` is called on the main actor per step (HUD updates);
    /// `completion` when all frames finish. UI playback of the engine's
    /// pre-computed trace — no re-simulation.
    func play(
        snapshots: [RobotSnapshot],
        teleportFrames: Set<Int> = [],
        onFrameIndex: @escaping @MainActor (Int) -> Void,
        completion: @escaping @MainActor () -> Void
    ) {
        guard !snapshots.isEmpty else {
            Task { @MainActor in completion() }
            return
        }

        let restY = self.robotRestY

        // Real-robot motion feel: driving time scales with distance, turning with
        // angle. Tuned so a full 100 cm drive reads as a deliberate roll (~0.7 s)
        // and a 90° pivot as a crisp turn (~0.4 s).
        let driveSpeed:  Float        = 14.0     // SceneKit units / second (10 units ≈ 100 cm)
        let turnSpeed:   Double       = 240.0    // degrees / second
        let actionDur:   TimeInterval = 0.26     // arm/gripper/mechanism-only frame
        let teleportDur: TimeInterval = 0.26

        // One duration per frame, so body + wheels + arm stay perfectly in sync.
        func frameDist(_ idx: Int) -> Float {
            let (tx, tz) = worldXZ(snapshots[idx].pose.position)
            let (px, pz) = worldXZ(snapshots[idx - 1].pose.position)
            return sqrt((tx - px) * (tx - px) + (tz - pz) * (tz - pz))
        }
        func frameTurn(_ idx: Int) -> Double {
            var d = abs(snapshots[idx].pose.headingDegrees - snapshots[idx - 1].pose.headingDegrees)
                .truncatingRemainder(dividingBy: 360)
            if d > 180 { d = 360 - d }
            return d
        }
        var durations: [TimeInterval] = []
        durations.reserveCapacity(snapshots.count)
        for idx in snapshots.indices {
            guard idx > 0 else { durations.append(0); continue }
            if teleportFrames.contains(idx) {
                durations.append(teleportDur)
            } else {
                let dist = frameDist(idx)
                let turn = frameTurn(idx)
                if dist > 0.01 {
                    durations.append(TimeInterval(min(max(dist / driveSpeed, 0.22), 1.4)))
                } else if turn > 0.5 {
                    durations.append(min(max(turn / turnSpeed, 0.16), 0.7))
                } else {
                    durations.append(actionDur)
                }
            }
        }

        // ---- Robot body: drive straight + pivot in place, per frame ----
        var actions: [SCNAction] = []
        for (idx, snap) in snapshots.enumerated() {
            let (tx, tz) = worldXZ(snap.pose.position)
            let targetPos = SCNVector3(tx, restY, tz)
            let targetYRot = CGFloat(headingToYRot(snap.pose.headingDegrees))
            let dur = durations[idx]

            let moveAction: SCNAction
            if idx == 0 {
                moveAction = SCNAction.move(to: targetPos, duration: 0)
            } else if teleportFrames.contains(idx) {
                // Genuine returnHome(): the rover is lifted to base, not driven.
                let fadeOut = SCNAction.fadeOut(duration: 0.12)
                let moveTo  = SCNAction.move(to: targetPos, duration: 0)
                let fadeIn  = SCNAction.fadeIn(duration: 0.12)
                moveAction  = SCNAction.sequence([fadeOut, moveTo, fadeIn])
            } else {
                let mv = SCNAction.move(to: targetPos, duration: dur)
                mv.timingMode = .easeInEaseOut
                moveAction = mv
            }

            // Pivot in place over the frame (a no-op when heading is unchanged).
            let rotAction = SCNAction.rotateTo(x: 0, y: targetYRot, z: 0,
                                               duration: idx == 0 ? 0 : dur,
                                               usesShortestUnitArc: true)
            rotAction.timingMode = .easeInEaseOut

            let isOpen   = snap.isGripperOpen
            let jawSpread: Float = isOpen ? 0.10 : 0.02

            let snapCopy = snap
            let idxCopy  = idx

            let updateBlock = SCNAction.run { [weak self] _ in
                guard let self else { return }
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    self.applyItemStates(snapCopy.itemStates,
                                         heldObjectId: snapCopy.heldObjectId,
                                         robotPos: targetPos)
                    self.applyMechanismStates(snapCopy.mechanismStates)
                    self.updateGripperJaws(open: isOpen, spread: jawSpread)
                    onFrameIndex(idxCopy)
                }
            }

            let group = SCNAction.group([moveAction, rotAction])
            let step  = SCNAction.sequence([group, updateBlock])
            actions.append(step)
        }

        // ---- Arm: articulate within each frame, synced to its duration ----
        var armActions: [SCNAction] = []
        for (idx, snap) in snapshots.enumerated() {
            let dur = durations[idx]
            let targetArmAngle = Float(snap.armAngle) * .pi / 180.0
            let armAction = SCNAction.rotateTo(x: CGFloat(-targetArmAngle), y: 0, z: 0,
                                               duration: idx == 0 ? 0 : dur * 0.5,
                                               usesShortestUnitArc: true)
            let wait = SCNAction.wait(duration: idx == 0 ? 0 : dur * 0.5)
            armActions.append(SCNAction.sequence([armAction, wait]))
        }
        armNode.runAction(.sequence(armActions))

        // ---- Drive-wheel spin, proportional to distance, over the same duration ----
        if !wheelNodes.isEmpty {
            let wheelR = 0.095 * robotScale
            var wheelActions: [SCNAction] = []
            for idx in snapshots.indices {
                guard idx > 0 else { wheelActions.append(SCNAction.wait(duration: 0)); continue }
                let dur = durations[idx]
                if teleportFrames.contains(idx) {
                    wheelActions.append(SCNAction.wait(duration: dur))
                    continue
                }
                let angle = CGFloat(frameDist(idx) / wheelR)
                let spin = SCNAction.rotateBy(x: angle, y: 0, z: 0, duration: dur)
                spin.timingMode = .easeInEaseOut
                wheelActions.append(spin)
            }
            let wheelSeq = SCNAction.sequence(wheelActions)
            for wheel in wheelNodes { wheel.runAction(wheelSeq) }
        }

        let sequence = SCNAction.sequence(actions)
        robotNode.runAction(sequence) {
            DispatchQueue.main.async {
                Task { @MainActor in completion() }
            }
        }
    }

    /// Reset the robot + all items to initial field state.
    func reset() {
        robotNode.removeAllActions()
        armNode.removeAllActions()
        lastHeldId = nil
        for wheel in wheelNodes {
            wheel.removeAllActions()
            wheel.eulerAngles = SCNVector3(0, 0, 0)
        }
        for glow in depositGlowNodes.values {
            glow.removeAllActions()
            glow.opacity = 0.0
        }

        let homePose = world.resolvedHomePose
        let (hx, hz) = worldXZ(homePose.position)
        robotNode.position      = SCNVector3(hx, robotRestY, hz)
        robotNode.eulerAngles.y = headingToYRot(homePose.headingDegrees)
        armNode.eulerAngles     = SCNVector3(0, 0, 0)
        robotNode.opacity       = 1.0

        for item in world.items {
            let node = itemNodes[item.id]
            let (ix, iz) = worldXZ(item.position)
            node?.position = SCNVector3(ix, tableTopY + 0.12, iz)
            node?.isHidden = false
            node?.opacity  = 1.0
        }

        updateGripperJaws(open: true, spread: 0.10)

        // Restore mechanisms to their un-activated pose.
        activatedMechs.removeAll()
        for (id, node) in mechanismNodes {
            node.removeAllActions()
            node.eulerAngles = SCNVector3(0, node.eulerAngles.y, 0)
            node.opacity = 1.0
            if let p = mechanismResetTransforms[id] { node.position = p }
        }
    }

    // MARK: - Mechanism animation

    /// Animate any mechanism that flipped to activated on this frame.
    private func applyMechanismStates(_ states: [MechanismState]) {
        for state in states where state.isActivated && !activatedMechs.contains(state.id) {
            activatedMechs.insert(state.id)
            guard let node = mechanismNodes[state.id],
                  let mech = world.mechanism(id: state.id) else { continue }
            switch mech.kind {
            case .lever:
                // Tip the handle forward ~72°.
                let tip = SCNAction.rotateTo(x: CGFloat(72.0 * .pi / 180), y: 0, z: 0,
                                             duration: 0.45, usesShortestUnitArc: true)
                tip.timingMode = .easeInEaseOut
                node.runAction(tip)
            case .platform:
                // Rise 0.5 units.
                let up = SCNAction.moveBy(x: 0, y: 0.5, z: 0, duration: 0.5)
                up.timingMode = .easeInEaseOut
                node.runAction(up)
            case .gate:
                if world.id == "field_warehouse" {
                    // Roll-up bay door: lift up on its rails, clearing the lane.
                    let lift = SCNAction.moveBy(x: 0, y: 0.56, z: 0, duration: 0.55)
                    lift.timingMode = .easeInEaseOut
                    let fade = SCNAction.sequence([SCNAction.wait(duration: 0.35),
                                                   SCNAction.fadeOpacity(to: 0.55, duration: 0.30)])
                    node.runAction(.group([lift, fade]))
                } else {
                    // Drop into the mat + fade slightly, opening the lane.
                    let drop = SCNAction.moveBy(x: 0, y: -0.42, z: 0, duration: 0.5)
                    drop.timingMode = .easeIn
                    let dim  = SCNAction.fadeOpacity(to: 0.25, duration: 0.5)
                    node.runAction(.group([drop, dim]))
                }
            case .launcher:
                // Blast off: a brief crouch, then accelerate up and fade into "space".
                let crouch = SCNAction.moveBy(x: 0, y: -0.03, z: 0, duration: 0.12)
                let liftUp = SCNAction.moveBy(x: 0, y: 7.0, z: 0, duration: 1.15)
                liftUp.timingMode = .easeIn
                let spin   = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 1.2, z: 0, duration: 1.15)
                let fade   = SCNAction.sequence([SCNAction.wait(duration: 0.7),
                                                 SCNAction.fadeOpacity(to: 0.0, duration: 0.45)])
                node.runAction(.sequence([crouch, .group([liftUp, spin, fade])]))
            case .excavator:
                // Pull free: the sample rises out of the mound with a little twist.
                let rise  = SCNAction.moveBy(x: 0, y: 0.34, z: 0, duration: 0.5)
                rise.timingMode = .easeOut
                let twist = SCNAction.rotateBy(x: 0, y: CGFloat.pi * 0.5, z: 0, duration: 0.5)
                node.runAction(.group([rise, twist]))
            }
        }
    }

    // MARK: - Helpers

    private func applyItemStates(_ states: [ItemState],
                                  heldObjectId: String?,
                                  robotPos: SCNVector3) {
        for state in states {
            guard let node = itemNodes[state.id] else { continue }
            if state.isHeld && state.id == heldObjectId {
                // Carried: glide the item to the gripper (with a slight lift) instead
                // of snapping — reads as the rover actually holding it.
                let target = SCNVector3(robotPos.x, robotPos.y - 0.02, robotPos.z - 0.55)
                let mv = SCNAction.move(to: target, duration: 0.16)
                mv.timingMode = .easeInEaseOut
                node.runAction(mv)
            } else if let pos = state.position {
                let (ix, iz) = worldXZ(pos)
                let target = SCNVector3(ix, tableTopY + 0.12, iz)
                // Settle down softly (covers both resting items and a just-released drop).
                let mv = SCNAction.move(to: target, duration: 0.22)
                mv.timingMode = .easeOut
                node.runAction(mv)
                node.isHidden = false
            }
        }

        // Deposit reaction: if the held item was released this frame, pulse the
        // deposit zone it landed in so delivery has a visible payoff.
        if let prev = lastHeldId, heldObjectId != prev,
           let released = states.first(where: { $0.id == prev }),
           let pos = released.position {
            pulseDepositZone(containing: pos)
        }
        lastHeldId = heldObjectId
    }

    /// Briefly light up any deposit zone whose rect contains `pos`.
    private func pulseDepositZone(containing pos: Vec2) {
        for zone in world.zones where zone.kind == .deposit && zone.rect.contains(pos) {
            guard let glow = depositGlowNodes[zone.id] else { continue }
            let up   = SCNAction.fadeOpacity(to: 0.70, duration: 0.16)
            let down = SCNAction.fadeOpacity(to: 0.0,  duration: 0.60)
            up.timingMode = .easeOut; down.timingMode = .easeInEaseOut
            glow.runAction(.sequence([up, down]))
        }
    }

    private func updateGripperJaws(open: Bool, spread: Float) {
        let jaws = gripperNode.childNodes
        guard jaws.count >= 2 else { return }
        jaws[0].position.x = open ? -0.09 : -0.03
        jaws[1].position.x = open ?  0.09 :  0.03
    }
}

// MARK: - UIColor helpers

private extension UIColor {
    func darkened(by factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: s, brightness: max(0, b - factor), alpha: a)
    }

    func lightened(by factor: CGFloat) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return UIColor(hue: h, saturation: min(1, s - factor * 0.3),
                       brightness: min(1, b + factor), alpha: a)
    }
}

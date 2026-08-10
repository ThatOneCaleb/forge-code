/// Builds the `RobotAPIBindings` that connect the interpreter to the robot
/// model and field world, recording every action as a `RobotSnapshot`.
///
/// Heading/turn convention (matches Pose.swift):
///   0° = north (+Y), increasing clockwise. turnRight adds degrees; turnLeft subtracts.
///
/// Sensor reading convention:
///   - distance(): forward range to the nearest obstacle or out-of-bounds wall, cm.
///   - color():    string from the coloured region the robot centre is standing in,
///                 or "" if none.
///   - lineLeft/lineRight: true when the respective sensor point is within a line's width.
///   - gyro():     current headingDegrees (same as pose.headingDegrees).
///   - limitSwitch(): true when arm is within 5° of 0° (fully raised) or 90° (fully lowered).
///   - wallAhead():  true when distance() ≤ wallAheadThresholdCm.
///
/// Arm angle convention:
///   0° = raised/horizontal; 90° = fully lowered (pickup/deposit position).
///   Pickup gating: arm must be ≥ armLoweredThreshold (60°) AND gripper must
///   be open to pick up, or closed to deposit.

/// Internal control flow: the API closure throws `RoboticsSimulator.ActionError`
/// to signal budget exceeded or collision. The simulator catches and wraps it.

// MARK: - Collision policy

/// Determines what happens when a drive move would collide with an obstacle
/// or the field boundary.
///
/// - `.failRun` (default): the run terminates immediately with a friendly error.
///   This is the behaviour for single-mission runs; all pre-existing tests rely on it.
/// - `.blockAndContinue`: the robot stops flush against the obstacle (at the last
///   safe sub-step) and execution continues with the next statement. The robot is
///   "stuck" but the program keeps running. Used by `runMatch` so a bump does not
///   end a whole competitive run; a subsequent `returnHome()` can recover the rover.
public enum CollisionPolicy: Equatable, Sendable {
    case failRun
    case blockAndContinue
}

// MARK: - Sensor offsets

/// How far each line sensor is from the robot centre (cm).
private let lineSensorOffset: Double = 12

/// Distance (cm) at which `wallAhead()` returns true.
private let wallAheadThresholdCm: Double = 25

/// How many cm ahead of the robot the forward distance sensor "looks".
/// Returns distance to first obstacle or boundary wall from that forward point.
private let distanceSensorMaxRange: Double = 300

// MARK: - Factory

/// Builds a fully-connected set of `RobotAPIBindings` bound to a mutable
/// robot + world + snapshot recorder.
struct RobotAPIFactory {

    /// Shared mutable state threaded through all closures.
    final class SimState {
        var robot:       RobotModel
        var world:       FieldWorld
        var snapshots:   [RobotSnapshot]
        var sensorLog:   [SensorEvent]
        /// Mutable item states (position can become nil when picked up).
        var itemStates:  [String: ItemState]    // keyed by item id
        /// Zones items have been deposited into: itemId -> zoneId
        var depositLog:  [String: String]
        var actionCount: Int
        let actionBudget: Int
        /// How to handle collisions during this run.
        let collisionPolicy: CollisionPolicy
        /// Precision tokens remaining. nil = single-mission run (no token bookkeeping).
        var tokensRemaining: Int?
        /// Activation state per mechanism id (one-way: false → true).
        var mechanismStates: [String: Bool]

        init(robot: RobotModel, world: FieldWorld, actionBudget: Int,
             collisionPolicy: CollisionPolicy = .failRun,
             startingTokens: Int? = nil) {
            self.robot            = robot
            self.world            = world
            self.snapshots        = []
            self.sensorLog        = []
            self.actionCount      = 0
            self.actionBudget     = actionBudget
            self.depositLog       = [:]
            self.collisionPolicy  = collisionPolicy
            self.tokensRemaining  = startingTokens
            // Initialise item states from the world
            var states: [String: ItemState] = [:]
            for item in world.items {
                states[item.id] = ItemState(id: item.id, position: item.position)
            }
            self.itemStates = states
            // All mechanisms start un-activated
            var mechs: [String: Bool] = [:]
            for mech in world.mechanisms { mechs[mech.id] = false }
            self.mechanismStates = mechs
        }

        var currentItemStatesList: [ItemState] {
            world.items.compactMap { itemStates[$0.id] }
        }

        var currentMechanismStatesList: [MechanismState] {
            world.mechanisms.map {
                MechanismState(id: $0.id, isActivated: mechanismStates[$0.id] ?? false)
            }
        }

        func snapshot() -> RobotSnapshot {
            RobotSnapshot(
                pose:          robot.pose,
                armAngle:      robot.armAngle,
                isGripperOpen: robot.isGripperOpen,
                heldObjectId:  robot.heldObjectId,
                itemStates:    currentItemStatesList,
                mechanismStates: currentMechanismStatesList
            )
        }

        /// Activate any un-activated mechanism whose trigger matches and whose
        /// trigger radius contains the robot centre. One-way; appends a keyframe
        /// showing the new state plus a `mechanismActivated` event for UI timing.
        /// A gate mechanism with `unlocksObstacleId` removes that obstacle from
        /// the (mutable) world copy — opening the corridor for the rest of the run.
        func checkMechanisms(trigger: MechanismTrigger) {
            for mech in world.mechanisms {
                guard mechanismStates[mech.id] == false,
                      mech.trigger == trigger else { continue }
                // Reach = the mechanism's radius plus any bonus from the attachment.
                let reach = mech.triggerRadius + robot.attachment.reachBonus
                guard robot.pose.position.distance(to: mech.position) <= reach else { continue }
                // Attachment gate: the right tool must be mounted.
                if let required = mech.requiredAttachment, robot.attachment != required { continue }
                // Trigger-specific preconditions.
                switch trigger {
                case .bump:
                    break
                case .armPress:
                    if !robot.isArmLowered { continue }
                case .gripperPull:
                    // A pull = arm lowered AND gripper closed on the buried object.
                    if !robot.isArmLowered || robot.isGripperOpen { continue }
                }
                mechanismStates[mech.id] = true
                if let obsId = mech.unlocksObstacleId {
                    world.obstacles.removeAll { $0.id == obsId }
                }
                recordSnapshot()
                recordSensorEvent(.mechanismActivated(mech.id))
            }
        }

        func recordSnapshot() {
            snapshots.append(snapshot())
        }

        func recordSensorEvent(_ kind: SensorEventKind) {
            sensorLog.append(SensorEvent(frameIndex: snapshots.count - 1, kind: kind))
        }

        func checkActionBudget() throws {
            actionCount += 1
            if actionCount > actionBudget {
                throw SimActionError.actionBudgetExceeded(limit: actionBudget)
            }
        }
    }

    /// Errors thrown by action closures (caught by the simulator).
    enum SimActionError: Error {
        case collision(obstacleId: String)
        case outOfBounds
        case actionBudgetExceeded(limit: Int)
    }

    static func makeBindings(state: SimState) -> RobotAPIBindings {
        var b = RobotAPIBindings()

        // Record the initial snapshot before any actions.
        state.recordSnapshot()

        // MARK: drive.forward(cm)
        b.driveForward = { cm in
            guard cm > 0 else { return .void }   // zero or negative is a no-op
            try state.checkActionBudget()
            let step = min(cm, 500.0)
            var remaining = step
            let stepSize: Double = 1.0             // simulate in 1-cm increments
            while remaining > 0 {
                let delta = min(stepSize, remaining)
                var newPose = state.robot.pose
                newPose.moveForward(cm: delta)
                // Collision checks — test the leading edge (centre + footprintRadius ahead)
                // so the robot's body is respected, not just its centre point.
                let leadEdge = newPose.position + newPose.headingVector * state.robot.footprintRadius
                do {
                    try checkBounds(newPose.position, state: state)
                    try checkObstacles(leadEdge, state: state, robot: state.robot)
                } catch {
                    // Collision or out-of-bounds — apply policy
                    switch state.collisionPolicy {
                    case .failRun:
                        throw error
                    case .blockAndContinue:
                        // Stop at the last safe position (don't move this sub-step)
                        state.recordSnapshot()
                        state.checkMechanisms(trigger: .bump)
                        return .void
                    }
                }
                state.robot.pose = newPose
                state.robot.encoderDistance += delta
                remaining -= delta
            }
            state.recordSnapshot()
            state.checkMechanisms(trigger: .bump)
            return .void
        }

        // MARK: drive.backward(cm)
        b.driveBackward = { cm in
            guard cm > 0 else { return .void }   // zero or negative is a no-op
            try state.checkActionBudget()
            let step = min(cm, 500.0)
            var remaining = step
            let stepSize: Double = 1.0
            while remaining > 0 {
                let delta = min(stepSize, remaining)
                var newPose = state.robot.pose
                newPose.moveForward(cm: -delta)
                // Collision checks — test the trailing edge (opposite of heading)
                let trailEdge = newPose.position - newPose.headingVector * state.robot.footprintRadius
                do {
                    try checkBounds(newPose.position, state: state)
                    try checkObstacles(trailEdge, state: state, robot: state.robot)
                } catch {
                    switch state.collisionPolicy {
                    case .failRun:
                        throw error
                    case .blockAndContinue:
                        state.recordSnapshot()
                        state.checkMechanisms(trigger: .bump)
                        return .void
                    }
                }
                state.robot.pose = newPose
                state.robot.encoderDistance -= delta
                remaining -= delta
            }
            state.recordSnapshot()
            state.checkMechanisms(trigger: .bump)
            return .void
        }

        // MARK: drive.turnLeft(deg)
        b.driveTurnLeft = { deg in
            try state.checkActionBudget()
            state.robot.pose.turnLeft(degrees: deg)
            state.recordSnapshot()
            return .void
        }

        // MARK: drive.turnRight(deg)
        b.driveTurnRight = { deg in
            try state.checkActionBudget()
            state.robot.pose.turnRight(degrees: deg)
            state.recordSnapshot()
            return .void
        }

        // MARK: drive.distance()
        b.driveDistance = {
            .number(state.robot.encoderDistance)
        }

        // MARK: drive.heading()
        b.driveHeading = {
            .number(state.robot.pose.headingDegrees)
        }

        // MARK: arm.moveTo(deg)
        b.armMoveTo = { deg in
            try state.checkActionBudget()
            state.robot.armAngle = min(max(deg, 0), 180)
            state.recordSnapshot()
            state.checkMechanisms(trigger: .armPress)
            return .void
        }

        // MARK: arm.raise()
        b.armRaise = {
            try state.checkActionBudget()
            state.robot.armAngle = RobotModel.armRaisedAngle
            state.recordSnapshot()
            return .void
        }

        // MARK: arm.lower()
        b.armLower = {
            try state.checkActionBudget()
            state.robot.armAngle = RobotModel.armLoweredAngle
            state.recordSnapshot()
            state.checkMechanisms(trigger: .armPress)
            return .void
        }

        // MARK: arm.angle()
        b.armAngle = {
            .number(state.robot.armAngle)
        }

        // MARK: gripper.open()
        b.gripperOpen = {
            try state.checkActionBudget()
            let wasHolding = state.robot.heldObjectId

            if let itemId = wasHolding {
                // Check if we're over a deposit zone
                let robotPos = state.robot.pose.position
                if let zone = state.world.zones.first(where: {
                    $0.kind == .deposit && $0.rect.contains(robotPos)
                }) {
                    // Deposit the item into the zone
                    state.itemStates[itemId]?.isHeld   = false
                    state.itemStates[itemId]?.position  = zone.rect.centre
                    state.itemStates[itemId]?.inZoneId  = zone.id
                    state.depositLog[itemId]            = zone.id
                } else {
                    // Drop in place
                    state.itemStates[itemId]?.isHeld   = false
                    state.itemStates[itemId]?.position  = robotPos
                }
                state.robot.heldObjectId = nil
            }
            state.robot.isGripperOpen = true
            state.recordSnapshot()
            return .void
        }

        // MARK: gripper.close()
        b.gripperClose = {
            try state.checkActionBudget()
            state.robot.isGripperOpen = false

            // Only pick up if arm is lowered and not already holding something
            if state.robot.isArmLowered && state.robot.heldObjectId == nil {
                let robotPos = state.robot.pose.position
                let reachBonus = state.robot.attachment.reachBonus
                // Find closest pickable item within pickup radius (+ attachment reach)
                for item in state.world.items {
                    guard let itemState = state.itemStates[item.id],
                          !itemState.isHeld,
                          itemState.inZoneId == nil,
                          let itemPos = itemState.position else { continue }
                    if robotPos.distance(to: itemPos) <= item.pickupRadius + reachBonus {
                        // Pick it up
                        state.robot.heldObjectId          = item.id
                        state.itemStates[item.id]?.isHeld = true
                        state.itemStates[item.id]?.position = nil
                        break
                    }
                }
            }
            // A grab can also pry a buried sample loose (excavator mechanism).
            state.checkMechanisms(trigger: .gripperPull)
            state.recordSnapshot()
            return .void
        }

        // MARK: gripper.isHolding()
        b.gripperIsHolding = {
            .bool(state.robot.heldObjectId != nil)
        }

        // MARK: distance()
        b.distance = {
            let val = forwardDistance(state: state)
            state.recordSensorEvent(.distance(val))
            return .number(val)
        }

        // MARK: color()
        b.color = {
            let val = colorAtPosition(state.robot.pose.position, state: state)
            state.recordSensorEvent(.color(val))
            return .string(val)
        }

        // MARK: color.isRed()
        // Log a .color sensor event so detectColorInZone objectives can be satisfied
        // even when the program uses color.isRed() instead of color().
        b.colorIsRed = {
            let val = colorAtPosition(state.robot.pose.position, state: state)
            state.recordSensorEvent(.color(val))
            return .bool(val.lowercased() == "red")
        }

        // MARK: color.isBlue()
        b.colorIsBlue = {
            let val = colorAtPosition(state.robot.pose.position, state: state)
            state.recordSensorEvent(.color(val))
            return .bool(val.lowercased() == "blue")
        }

        // MARK: color.isGreen()
        b.colorIsGreen = {
            let val = colorAtPosition(state.robot.pose.position, state: state)
            state.recordSensorEvent(.color(val))
            return .bool(val.lowercased() == "green")
        }

        // MARK: lineLeft()
        b.lineLeft = {
            let sensorPos = leftSensorPosition(state.robot.pose)
            let onLine = isOnLine(sensorPos, world: state.world)
            state.recordSensorEvent(.lineLeft(onLine))
            return .bool(onLine)
        }

        // MARK: lineRight()
        b.lineRight = {
            let sensorPos = rightSensorPosition(state.robot.pose)
            let onLine = isOnLine(sensorPos, world: state.world)
            state.recordSensorEvent(.lineRight(onLine))
            return .bool(onLine)
        }

        // MARK: gyro()
        b.gyro = {
            let val = state.robot.pose.headingDegrees
            state.recordSensorEvent(.gyro(val))
            return .number(val)
        }

        // MARK: limitSwitch()
        b.limitSwitch = {
            let angle = state.robot.armAngle
            let atLimit = (angle <= 5) || (abs(angle - RobotModel.armLoweredAngle) <= 5)
            state.recordSensorEvent(.limitSwitch(atLimit))
            return .bool(atLimit)
        }

        // MARK: wallAhead()
        b.wallAhead = {
            let d = forwardDistance(state: state)
            let result = d <= wallAheadThresholdCm
            state.recordSensorEvent(.wallAhead(result))
            return .bool(result)
        }

        // MARK: wait(ms)
        b.wait = { ms in
            try state.checkActionBudget()
            state.recordSensorEvent(.wait(ms))
            state.recordSnapshot()
            return .void
        }

        // MARK: print(x)
        b.print_ = { val in
            state.recordSensorEvent(.print_(val.displayString))
            return .void
        }

        // MARK: returnHome()
        //
        // Teleports the robot to the field's resolved home pose. Costs 1 action
        // from the budget. Any held item stays held (you carried it home).
        //
        // Precision tokens:
        //   - In a match run (tokensRemaining != nil): spends 1 token (floored at 0).
        //   - In a single-mission run (tokensRemaining == nil): no token bookkeeping;
        //     returnHome() still works as a teleport-home with 0 token side-effects.
        b.returnHome = {
            try state.checkActionBudget()
            let homePose = state.world.resolvedHomePose
            // Spend a precision token if we're in a match context
            if let tokens = state.tokensRemaining {
                state.tokensRemaining = max(0, tokens - 1)
            }
            // Teleport — no sub-step collision checking (it's an instant rescue action)
            state.robot.pose = homePose
            state.recordSensorEvent(.returnHome(homePose))
            state.recordSnapshot()
            return .void
        }

        return b
    }

    // MARK: - Sensor implementations

    /// Forward distance: cast a ray from just ahead of the robot and find the
    /// nearest obstacle/boundary wall.
    private static func forwardDistance(state: SimState) -> Double {
        let pose = state.robot.pose
        let robotPos = pose.position
        let dir = pose.headingVector
        let maxDist = distanceSensorMaxRange
        let stepSize = 1.0
        var dist = 0.0
        while dist <= maxDist {
            dist += stepSize
            let probe = robotPos + dir * dist
            // Out of bounds?
            if !state.world.isInBounds(probe) { return dist }
            // Hit an obstacle?
            for obs in state.world.obstacles {
                if obs.rect.contains(probe) { return dist }
            }
        }
        return maxDist
    }

    /// Color at a specific position: first matching colored region, else "".
    private static func colorAtPosition(_ pos: Vec2, state: SimState) -> String {
        for region in state.world.coloredRegions {
            if region.rect.contains(pos) { return region.color }
        }
        return ""
    }

    /// Position of the left line sensor (90° CCW from heading, `lineSensorOffset` cm away).
    private static func leftSensorPosition(_ pose: Pose) -> Vec2 {
        let headingRad = pose.headingDegrees * .pi / 180
        // 90° to the left of heading
        let leftRad = headingRad - .pi / 2
        return Vec2(x: pose.position.x + rSin(leftRad) * lineSensorOffset,
                    y: pose.position.y + rCos(leftRad) * lineSensorOffset)
    }

    /// Position of the right line sensor (90° CW from heading).
    private static func rightSensorPosition(_ pose: Pose) -> Vec2 {
        let headingRad = pose.headingDegrees * .pi / 180
        let rightRad = headingRad + .pi / 2
        return Vec2(x: pose.position.x + rSin(rightRad) * lineSensorOffset,
                    y: pose.position.y + rCos(rightRad) * lineSensorOffset)
    }

    /// Whether a point is within any line's half-width.
    private static func isOnLine(_ pos: Vec2, world: FieldWorld) -> Bool {
        for line in world.lines {
            let halfWidth = line.width / 2
            for i in 0 ..< line.points.count - 1 {
                let a = line.points[i]
                let b = line.points[i + 1]
                if distanceToSegment(pos, a: a, b: b) <= halfWidth { return true }
            }
        }
        return false
    }

    /// Perpendicular distance from point p to segment a-b.
    private static func distanceToSegment(_ p: Vec2, a: Vec2, b: Vec2) -> Double {
        let ab  = b - a
        let ap  = p - a
        let len2 = ab.x * ab.x + ab.y * ab.y
        if len2 == 0 { return a.distance(to: p) }
        let t = min(max((ap.x * ab.x + ap.y * ab.y) / len2, 0), 1)
        let closest = Vec2(x: a.x + t * ab.x, y: a.y + t * ab.y)
        return closest.distance(to: p)
    }

    // MARK: - Collision helpers

    private static func checkBounds(_ pos: Vec2, state: SimState) throws {
        if !state.world.isInBounds(pos) {
            throw SimActionError.outOfBounds
        }
    }

    private static func checkObstacles(_ pos: Vec2, state: SimState, robot: RobotModel) throws {
        // `pos` is the robot's leading/trailing edge point (centre ± footprintRadius in direction
        // of travel), so we test the raw obstacle rect without further expansion.
        for obs in state.world.obstacles {
            if obs.rect.contains(pos) {
                throw SimActionError.collision(obstacleId: obs.id)
            }
        }
    }
}

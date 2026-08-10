/// Runs a `Program` against a `Challenge` and produces a deterministic
/// `ExecutionResult` with a full frame trace.
///
/// Pure and value-based: the same program + challenge always yields the
/// same result. The simulator focuses on execution and does not police
/// `allowedCommands` (a palette/parser concern).
public struct Simulator {
    /// Maximum number of atomic steps and loop iterations before a run is
    /// considered runaway.
    public let stepBudget: Int

    public init(stepBudget: Int = 1000) {
        self.stepBudget = stepBudget
    }

    /// Internal signal used to unwind out of recursive execution when a
    /// run must stop early (crash or budget exhaustion).
    private enum Stop: Error {
        case failure(FailureReason)
    }

    /// Mutable execution context threaded through recursion.
    private struct Machine {
        var robot: RobotState
        var frames: [RobotState]
        var steps: Int
        var itemsCollected: Set<String>
        var moveStepsUsed: Int
    }

    public func run(program: Program, challenge: Challenge) -> ExecutionResult {
        // Reject over-budget programs before executing anything.
        if let maxBlocks = challenge.maxBlocks {
            let used = program.blockCount
            if used > maxBlocks {
                return ExecutionResult(
                    outcome: .failure(.ranOutOfBlocks(limit: maxBlocks, used: used)),
                    frames: [challenge.start]
                )
            }
        }

        var machine = Machine(
            robot: challenge.start,
            frames: [challenge.start],
            steps: 0,
            itemsCollected: [],
            moveStepsUsed: 0
        )

        do {
            try execute(program.commands, in: challenge, machine: &machine)
        } catch let Stop.failure(reason) {
            return ExecutionResult(
                outcome: .failure(reason),
                frames: machine.frames,
                itemsCollected: machine.itemsCollected,
                moveStepsUsed: machine.moveStepsUsed
            )
        } catch {
            // No other error types are thrown.
            return ExecutionResult(
                outcome: .failure(.tooManySteps(limit: stepBudget)),
                frames: machine.frames,
                itemsCollected: machine.itemsCollected,
                moveStepsUsed: machine.moveStepsUsed
            )
        }

        // Check goal position.
        guard machine.robot.position == challenge.goal else {
            return ExecutionResult(
                outcome: .failure(.didNotReachGoal(finalPosition: machine.robot.position)),
                frames: machine.frames,
                itemsCollected: machine.itemsCollected,
                moveStepsUsed: machine.moveStepsUsed
            )
        }

        // Check collection goal.
        let required = challenge.collectGoal ?? 0
        guard machine.itemsCollected.count >= required else {
            return ExecutionResult(
                outcome: .failure(.didNotCollectAll(
                    collected: machine.itemsCollected.count,
                    required: required
                )),
                frames: machine.frames,
                itemsCollected: machine.itemsCollected,
                moveStepsUsed: machine.moveStepsUsed
            )
        }

        // Compute star rating.
        var starRating: Int? = nil
        if let par = challenge.parMoves {
            let used = machine.moveStepsUsed
            starRating = used <= par ? 3
                       : used <= Int(Double(par) * 1.5) ? 2
                       : 1
        }

        return ExecutionResult(
            outcome: .success,
            frames: machine.frames,
            itemsCollected: machine.itemsCollected,
            moveStepsUsed: machine.moveStepsUsed,
            starRating: starRating
        )
    }

    // MARK: - Recursive executor

    private func execute(
        _ commands: [Command],
        in challenge: Challenge,
        machine: inout Machine
    ) throws {
        for command in commands {
            try execute(command, in: challenge, machine: &machine)
        }
    }

    private func execute(
        _ command: Command,
        in challenge: Challenge,
        machine: inout Machine
    ) throws {
        switch command {
        case .move:
            try tick(&machine)
            let next = machine.robot.cellAhead
            if !challenge.grid.contains(next) {
                throw Stop.failure(.wentOffGrid(to: next))
            }
            if challenge.grid.isObstacle(next) {
                throw Stop.failure(.hitWall(at: next))
            }
            machine.robot = machine.robot.movedForward()

            // Determine terrain effect at the cell just entered.
            let terrain = challenge.grid.terrain[machine.robot.position] ?? .normal
            switch terrain {
            case .mud:
                // Mud costs 2 move-steps.
                machine.moveStepsUsed += 2
            default:
                machine.moveStepsUsed += 1
            }

            machine.frames.append(machine.robot)

            // Auto-collect any item at the new position.
            collectItems(at: machine.robot.position, grid: challenge.grid, machine: &machine)

            // Apply post-move terrain effects.
            switch terrain {
            case .ice:
                applyIceSlide(in: challenge.grid, machine: &machine)
            case .conveyorNorth:
                applyConveyor(direction: .up, grid: challenge.grid, machine: &machine)
            case .conveyorSouth:
                applyConveyor(direction: .down, grid: challenge.grid, machine: &machine)
            case .conveyorEast:
                applyConveyor(direction: .right, grid: challenge.grid, machine: &machine)
            case .conveyorWest:
                applyConveyor(direction: .left, grid: challenge.grid, machine: &machine)
            case let .portal(id):
                applyPortal(id: id, grid: challenge.grid, machine: &machine)
            case .normal, .mud:
                break
            }

        case .turnLeft:
            try tick(&machine)
            machine.robot = machine.robot.turnedLeft()
            machine.frames.append(machine.robot)

        case .turnRight:
            try tick(&machine)
            machine.robot = machine.robot.turnedRight()
            machine.frames.append(machine.robot)

        case let .repeatBlock(count, body):
            var remaining = max(0, count)
            while remaining > 0 {
                // Each loop iteration counts against the step budget so
                // empty/huge loops can't run forever.
                try tick(&machine)
                try execute(body, in: challenge, machine: &machine)
                remaining -= 1
            }

        case let .ifWallAhead(body):
            if challenge.grid.isBlocked(machine.robot.cellAhead) {
                try execute(body, in: challenge, machine: &machine)
            }
        }
    }

    // MARK: - Terrain side-effects

    /// Auto-collects any uncollected item sitting at the given position.
    private func collectItems(
        at position: Position,
        grid: Grid,
        machine: inout Machine
    ) {
        for item in grid.items where item.position == position {
            machine.itemsCollected.insert(item.id)
        }
    }

    /// Ice: slide one additional cell in the robot's current facing direction.
    /// Stops silently if the next cell is blocked or OOB; never recursive.
    private func applyIceSlide(in grid: Grid, machine: inout Machine) {
        let slideTarget = machine.robot.cellAhead
        guard grid.contains(slideTarget), !grid.isObstacle(slideTarget) else {
            return  // stays at current cell; no failure
        }
        machine.robot = machine.robot.movedForward()
        machine.frames.append(machine.robot)
        collectItems(at: machine.robot.position, grid: grid, machine: &machine)
        // Do NOT apply further ice or conveyor on the slide-destination cell.
    }

    /// Conveyor: push the robot one cell in `direction` after the move.
    /// Stays silently if the push target is blocked or OOB; never recursive.
    private func applyConveyor(
        direction: Direction,
        grid: Grid,
        machine: inout Machine
    ) {
        let delta = direction.delta
        let pushTarget = Position(
            x: machine.robot.position.x + delta.dx,
            y: machine.robot.position.y + delta.dy
        )
        guard grid.contains(pushTarget), !grid.isObstacle(pushTarget) else {
            return  // stays at current cell; no failure
        }
        machine.robot = RobotState(position: pushTarget, facing: machine.robot.facing)
        machine.frames.append(machine.robot)
        collectItems(at: machine.robot.position, grid: grid, machine: &machine)
        // Do NOT apply conveyor or any other terrain recursively.
    }

    /// Portal: teleport the robot to the OTHER portal cell with the same id.
    /// If no matching partner exists, treats as normal (graceful degradation).
    private func applyPortal(id: String, grid: Grid, machine: inout Machine) {
        // Find all portal positions with this id; pick the one that is NOT
        // the robot's current position (the exit portal).
        let partnerPosition = grid.terrain.first { entry in
            if case let .portal(pid) = entry.value {
                return pid == id && entry.key != machine.robot.position
            }
            return false
        }?.key

        guard let dest = partnerPosition else {
            return  // no partner — treat as normal
        }

        machine.robot = RobotState(position: dest, facing: machine.robot.facing)
        machine.frames.append(machine.robot)
        collectItems(at: machine.robot.position, grid: grid, machine: &machine)
    }

    /// Charges one unit against the step budget, failing if exhausted.
    private func tick(_ machine: inout Machine) throws {
        machine.steps += 1
        if machine.steps > stepBudget {
            throw Stop.failure(.tooManySteps(limit: stepBudget))
        }
    }
}

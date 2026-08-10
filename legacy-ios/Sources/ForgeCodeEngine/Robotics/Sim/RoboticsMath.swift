/// Minimal trigonometry shim for the robotics sim layer.
///
/// `Darwin` (the Apple C library) provides `sin`/`cos`. This is NOT
/// Foundation, SwiftUI, SwiftData, or UIKit — it's the platform C runtime,
/// available on both macOS and iOS. Isolated to one file to make the
/// dependency surface explicit and easy to audit.
///
/// Design note: using native platform math (rather than a Taylor series) for
/// accuracy in sensor distance and heading calculations.
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#endif

/// sin/cos wrappers used by Pose and RobotAPI. Angles in radians.
@inline(__always)
func rSin(_ radians: Double) -> Double { sin(radians) }

@inline(__always)
func rCos(_ radians: Double) -> Double { cos(radians) }

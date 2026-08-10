import SwiftData
import Foundation

/// The single local kid profile. MVP supports one kid; this model is
/// structured to be cleanly queryable for a future mentor/parent layer.
@Model
final class Kid {
    var id: UUID
    var name: String
    /// Rough age band, e.g. "8-10", "11-13", "14-15".
    var ageBand: String
    var joinedDate: Date
    /// IDs of lessons the kid has finished (ordered by completion time).
    var completedLessonIDs: [String]
    /// IDs of badges the kid has earned.
    var earnedBadgeIDs: [String]
    /// Consecutive-day streak count.
    var currentStreak: Int
    /// The last calendar date the app was opened (for streak calculation).
    var lastOpenedDate: Date?
    /// IDs of academy modules the kid has built (spending stars).
    var builtModuleIDs: [String] = []

    init(
        id: UUID = UUID(),
        name: String = "Coder",
        ageBand: String = "8-15",
        joinedDate: Date = Date(),
        completedLessonIDs: [String] = [],
        earnedBadgeIDs: [String] = [],
        currentStreak: Int = 0,
        lastOpenedDate: Date? = nil,
        builtModuleIDs: [String] = []
    ) {
        self.id = id
        self.name = name
        self.ageBand = ageBand
        self.joinedDate = joinedDate
        self.completedLessonIDs = completedLessonIDs
        self.earnedBadgeIDs = earnedBadgeIDs
        self.currentStreak = currentStreak
        self.lastOpenedDate = lastOpenedDate
        self.builtModuleIDs = builtModuleIDs
    }
}

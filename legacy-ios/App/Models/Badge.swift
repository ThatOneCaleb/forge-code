import SwiftData
import Foundation

/// A badge earned by the kid when completing a lesson.
///
/// Stored cleanly so a future mentor/parent layer can query which badges
/// a kid earned, when, and from which track.
@Model
final class Badge {
    var id: UUID
    /// The lesson that awarded this badge.
    var lessonID: String
    /// The kid who earned it (for future multi-profile support).
    var kidID: UUID
    var dateEarned: Date
    /// The lesson track, e.g. "codeBasics".
    var track: String

    init(
        id: UUID = UUID(),
        lessonID: String,
        kidID: UUID,
        dateEarned: Date = Date(),
        track: String
    ) {
        self.id = id
        self.lessonID = lessonID
        self.kidID = kidID
        self.dateEarned = dateEarned
        self.track = track
    }
}

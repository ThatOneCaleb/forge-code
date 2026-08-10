import ForgeCodeEngine

/// Loads static lesson content from the engine's bundled JSON.
///
/// This is the single place the app calls `LessonLibrary`; views and
/// view-models receive the already-loaded `[Lesson]` array. If loading
/// fails (bad bundle), a non-fatal empty array is returned and the
/// failure is logged — the kid never sees a crash.
@MainActor
final class LessonStore: @unchecked Sendable {
    static let shared = LessonStore()

    private(set) var codeBasicsLessons: [Lesson] = []
    private(set) var challengeLessons: [Lesson] = []

    private init() {
        do {
            codeBasicsLessons = try LessonLibrary.codeBasics()
        } catch {
            // Should never happen with a correct bundle; degrade gracefully.
            print("[LessonStore] Failed to load Code Basics lessons: \(error)")
        }
        do {
            challengeLessons = try LessonLibrary.challenges()
        } catch {
            print("[LessonStore] Failed to load Challenges lessons: \(error)")
        }
    }

    /// All available lessons across all tracks (expand as tracks are added).
    var allLessons: [Lesson] {
        codeBasicsLessons + challengeLessons
    }

    /// Return the lesson that follows the given lesson in the same track,
    /// or `nil` if the given lesson is the last in its track.
    func nextLesson(after lesson: Lesson) -> Lesson? {
        let trackLessons: [Lesson]
        switch lesson.track {
        case .codeBasics:
            trackLessons = codeBasicsLessons
        case .challenges:
            trackLessons = challengeLessons
        case .robotics:
            trackLessons = []
        }
        guard let idx = trackLessons.firstIndex(where: { $0.id == lesson.id }),
              idx + 1 < trackLessons.count
        else { return nil }
        return trackLessons[idx + 1]
    }
}

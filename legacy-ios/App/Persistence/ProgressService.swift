import SwiftData
import Foundation
import ForgeCodeEngine

/// Reads and writes Kid progress (badges, streaks, completed lessons) via
/// the SwiftData `ModelContext`. Views never touch the context directly.
@MainActor
final class ProgressService {

    private let context: ModelContext

    init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Kid

    /// Return the single local kid, seeding one on first launch if needed.
    func currentKid() throws -> Kid {
        let descriptor = FetchDescriptor<Kid>()
        let kids = try context.fetch(descriptor)
        if let kid = kids.first { return kid }
        let newKid = Kid()
        context.insert(newKid)
        try context.save()
        return newKid
    }

    /// Mark a lesson complete, award a badge, update streak, and save.
    func completeLesson(_ lesson: Lesson, for kid: Kid) throws {
        guard !kid.completedLessonIDs.contains(lesson.id) else { return }
        kid.completedLessonIDs.append(lesson.id)
        kid.earnedBadgeIDs.append(lesson.id)

        let badge = Badge(
            lessonID: lesson.id,
            kidID: kid.id,
            track: lesson.track.rawValue
        )
        context.insert(badge)
        updateStreak(for: kid)
        try context.save()
    }

    // MARK: - Streak

    /// Update `currentStreak` based on today vs `lastOpenedDate`.
    /// A consecutive calendar-day open increments the streak; a gap resets
    /// it to 1. Call on every app-open (idempotent within the same day).
    func recordAppOpen(for kid: Kid) throws {
        kid.currentStreak = updatedStreak(
            current: kid.currentStreak,
            lastOpened: kid.lastOpenedDate,
            today: Date()
        )
        kid.lastOpenedDate = Date()
        try context.save()
    }

    /// Pure, testable streak-update logic separated from persistence.
    func updatedStreak(current: Int, lastOpened: Date?, today: Date) -> Int {
        guard let last = lastOpened else { return 1 }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        switch daysSince {
        case 0: return current               // same calendar day — no change
        case 1: return current + 1           // consecutive day — extend streak
        default: return 1                    // gap — reset
        }
    }

    private func updateStreak(for kid: Kid) {
        kid.currentStreak = updatedStreak(
            current: kid.currentStreak,
            lastOpened: kid.lastOpenedDate,
            today: Date()
        )
        kid.lastOpenedDate = Date()
    }

    // MARK: - Build Log

    func addBuildLogEntry(
        kidID: UUID,
        noteText: String,
        photoFilename: String? = nil,
        tag: BuildLogTag = .coding
    ) throws {
        let entry = BuildLogEntry(
            kidID: kidID,
            noteText: noteText,
            photoFilename: photoFilename,
            tag: tag
        )
        context.insert(entry)
        try context.save()
    }

    func buildLogEntries(for kidID: UUID) throws -> [BuildLogEntry] {
        var descriptor = FetchDescriptor<BuildLogEntry>(
            predicate: #Predicate { $0.kidID == kidID },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 200
        return try context.fetch(descriptor)
    }

    func badges(for kidID: UUID) throws -> [Badge] {
        let descriptor = FetchDescriptor<Badge>(
            predicate: #Predicate { $0.kidID == kidID },
            sortBy: [SortDescriptor(\.dateEarned)]
        )
        return try context.fetch(descriptor)
    }

    // MARK: - Photo storage

    /// Save image data to the app's Documents directory and return the filename.
    func savePhoto(_ data: Data, filename: String) throws -> String {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(filename)
        try data.write(to: url)
        return filename
    }

    /// Load image data from Documents directory by filename.
    func loadPhoto(filename: String) -> Data? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let url = docs.appendingPathComponent(filename)
        return try? Data(contentsOf: url)
    }
}

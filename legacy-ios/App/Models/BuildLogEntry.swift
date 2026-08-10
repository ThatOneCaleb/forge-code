import SwiftData
import Foundation

/// A tag categorising a Build Log entry.
enum BuildLogTag: String, Codable, CaseIterable {
    case coding
    case robotics
    case other

    var displayName: String {
        switch self {
        case .coding: return "Coding"
        case .robotics: return "Robotics"
        case .other: return "Other"
        }
    }
}

/// A kid's reflective Build Log entry — a date-stamped note with an
/// optional photo and a tag. Photo images live in Documents; only the
/// filename is stored here (never the raw blob).
@Model
final class BuildLogEntry {
    var id: UUID
    /// The kid who wrote it (for future mentor/parent visibility).
    var kidID: UUID
    var date: Date
    var noteText: String
    /// Filename of the photo stored in the app's Documents directory, if any.
    var photoFilename: String?
    /// Raw tag value; decoded via `BuildLogTag`.
    var tagRaw: String

    var tag: BuildLogTag {
        get { BuildLogTag(rawValue: tagRaw) ?? .other }
        set { tagRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        kidID: UUID,
        date: Date = Date(),
        noteText: String = "",
        photoFilename: String? = nil,
        tag: BuildLogTag = .coding
    ) {
        self.id = id
        self.kidID = kidID
        self.date = date
        self.noteText = noteText
        self.photoFilename = photoFilename
        self.tagRaw = tag.rawValue
    }
}

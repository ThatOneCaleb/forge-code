/// Which learning track a lesson belongs to.
public enum Track: String, Codable, Hashable, Sendable, CaseIterable {
    case codeBasics
    case robotics
    case challenges
}

/// A single unit of static lesson content, decoded from bundled JSON.
///
/// Pure value type: no Foundation, no file system. The `LessonLibrary`
/// loader owns the actual decode.
public struct Lesson: Codable, Hashable, Sendable, Identifiable {
    public var id: String
    public var track: Track
    public var order: Int
    public var title: String
    public var introText: String
    public var goalDescription: String
    public var challenge: Challenge
    public var hintText: String?

    public init(
        id: String,
        track: Track,
        order: Int,
        title: String,
        introText: String,
        goalDescription: String,
        challenge: Challenge,
        hintText: String? = nil
    ) {
        self.id = id
        self.track = track
        self.order = order
        self.title = title
        self.introText = introText
        self.goalDescription = goalDescription
        self.challenge = challenge
        self.hintText = hintText
    }
}

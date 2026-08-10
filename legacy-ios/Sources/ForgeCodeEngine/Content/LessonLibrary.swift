import Foundation

/// Loads and decodes bundled lesson content.
///
/// This is the ONLY engine file allowed to `import Foundation` — it needs
/// `Bundle.module` and `JSONDecoder`. Everything it returns is a pure
/// value type the rest of the engine can use without Foundation.
public enum LessonLibrary {

    /// Errors surfaced when lesson content can't be loaded or decoded.
    public enum LoadError: Error, CustomStringConvertible {
        case resourceNotFound(String)
        case decodingFailed(String, underlying: Error)

        public var description: String {
            switch self {
            case let .resourceNotFound(name):
                return "Could not find bundled resource \(name)."
            case let .decodingFailed(name, underlying):
                return "Could not decode \(name): \(underlying)"
            }
        }
    }

    /// Decode the Code Basics lessons from `code_basics.json`, sorted by
    /// their `order`.
    public static func codeBasics() throws -> [Lesson] {
        try load(resource: "code_basics", extension: "json")
    }

    /// Decode the Challenges track from `challenges.json`, sorted by their
    /// `order`.
    public static func challenges() throws -> [Lesson] {
        try load(resource: "challenges", extension: "json")
    }

    /// Decode a `[Lesson]` array from a bundled JSON resource.
    public static func load(resource: String, extension ext: String) throws -> [Lesson] {
        guard let url = Bundle.module.url(forResource: resource, withExtension: ext) else {
            throw LoadError.resourceNotFound("\(resource).\(ext)")
        }
        do {
            let data = try Data(contentsOf: url)
            let lessons = try JSONDecoder().decode([Lesson].self, from: data)
            return lessons.sorted { $0.order < $1.order }
        } catch let error as LoadError {
            throw error
        } catch {
            throw LoadError.decodingFailed("\(resource).\(ext)", underlying: error)
        }
    }
}

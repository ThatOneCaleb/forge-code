/// The difficulty tier of a challenge, used for UI badges and map styling.
/// `nil` on legacy challenges (orders 1–25) — UI falls back to zone-based defaults.
public enum ChallengeDifficulty: String, Codable, Hashable, Sendable, CaseIterable {
    case easy
    case hard
    case superHard = "superHard"
}

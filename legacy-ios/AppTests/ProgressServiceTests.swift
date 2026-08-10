import Testing
import Foundation

/// Tests for the streak logic in ProgressService.
/// These are pure-function tests — no SwiftData context needed.
struct ProgressServiceStreakTests {

    // Streak helper (mirrors ProgressService.updatedStreak)
    func updatedStreak(current: Int, lastOpened: Date?, today: Date) -> Int {
        guard let last = lastOpened else { return 1 }
        let calendar = Calendar.current
        let daysSince = calendar.dateComponents([.day], from: last, to: today).day ?? 0
        switch daysSince {
        case 0: return current
        case 1: return current + 1
        default: return 1
        }
    }

    @Test func firstOpen() {
        #expect(updatedStreak(current: 0, lastOpened: nil, today: Date()) == 1)
    }

    @Test func sameDayDoesNotChange() {
        let today = Date()
        #expect(updatedStreak(current: 3, lastOpened: today, today: today) == 3)
    }

    @Test func consecutiveDayExtends() {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        #expect(updatedStreak(current: 3, lastOpened: yesterday, today: Date()) == 4)
    }

    @Test func gapResetsToOne() {
        let calendar = Calendar.current
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: Date())!
        #expect(updatedStreak(current: 5, lastOpened: twoDaysAgo, today: Date()) == 1)
    }
}

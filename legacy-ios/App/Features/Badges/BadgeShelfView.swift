import SwiftUI
import ForgeCodeEngine

/// Displays all Code Basics lessons as badges — earned (full colour) or
/// not yet earned (greyed/locked). The grid is always complete; kids can
/// see what they're working toward.
struct BadgeShelfView: View {
    let kid: Kid
    let progressService: ProgressService

    private let store = LessonStore.shared
    private let columns = [
        GridItem(.adaptive(minimum: 100, maximum: 140), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    streakHeader
                    badgeGrid
                }
                .padding(20)
            }
            .navigationTitle("Badges")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Subviews

    private var streakHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Day streak: \(kid.currentStreak)")
                    .font(.headline)
                Text("\(kid.earnedBadgeIDs.count) of \(store.allLessons.count) badges earned")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Day streak: \(kid.currentStreak). \(kid.earnedBadgeIDs.count) of \(store.allLessons.count) badges earned.")
    }

    private var badgeGrid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(store.allLessons) { lesson in
                let earned = kid.earnedBadgeIDs.contains(lesson.id)
                BadgeTileView(lesson: lesson, isEarned: earned)
            }
        }
    }
}

/// A single badge tile — earned or locked placeholder.
struct BadgeTileView: View {
    let lesson: Lesson
    let isEarned: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isEarned ? Color.yellow.opacity(0.2) : Color(.systemGray5))
                    .frame(width: 72, height: 72)

                Image(systemName: isEarned ? "seal.fill" : "lock.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(isEarned ? .yellow : Color(.systemGray3))

                if isEarned {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(y: 2)
                }
            }

            Text(lesson.title)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .foregroundStyle(isEarned ? .primary : .secondary)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .opacity(isEarned ? 1.0 : 0.6)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            isEarned
                ? "\(lesson.title) badge. Earned."
                : "\(lesson.title) badge. Not yet earned."
        )
    }
}

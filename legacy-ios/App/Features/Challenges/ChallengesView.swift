import SwiftUI
import ForgeCodeEngine

// MARK: - ChallengesView

struct ChallengesView: View {
    let kid: Kid
    let progressService: ProgressService

    @State private var selectedLesson: Lesson? = nil

    private let store = LessonStore.shared
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    private var challenges: [Lesson] {
        store.challengeLessons.sorted { $0.order < $1.order }
    }

    private var completedIDs: Set<String> {
        Set(kid.completedLessonIDs)
    }

    private var earnedCount: Int {
        challenges.filter { completedIDs.contains($0.id) }.count
    }

    // The lowest-order incomplete challenge
    private var nextUnlocked: String? {
        challenges.first { !completedIDs.contains($0.id) }?.id
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    badgeStrip
                    challengeGrid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 32)
            }
            .navigationTitle("Challenges")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(item: $selectedLesson) { lesson in
                ChallengeRoboticsView(
                    vm: ChallengeRoboticsViewModel(
                        lesson: lesson,
                        kid: kid,
                        progressService: progressService,
                        onComplete: { selectedLesson = nil }
                    )
                )
            }
        }
    }

    // MARK: - Badge Strip

    private var badgeStrip: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundStyle(.yellow)
                Text("\(earnedCount) / \(challenges.count) completed")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if kid.currentStreak > 0 {
                    Label("\(kid.currentStreak)", systemImage: "flame.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.orange)
                }
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(.systemFill))
                        .frame(height: 8)
                    Capsule()
                        .fill(Color.yellow)
                        .frame(
                            width: challenges.isEmpty ? 0 : geo.size.width * CGFloat(earnedCount) / CGFloat(challenges.count),
                            height: 8
                        )
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: earnedCount)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .padding(.top, 8)
    }

    // MARK: - Challenge Grid

    private var challengeGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(challenges) { lesson in
                let done = completedIDs.contains(lesson.id)
                let isNext = lesson.id == nextUnlocked
                ChallengeTile(lesson: lesson, isDone: done, isNext: isNext)
                    .onTapGesture {
                        if done || isNext {
                            selectedLesson = lesson
                        }
                    }
            }
        }
    }
}

// MARK: - ChallengeTile

private struct ChallengeTile: View {
    let lesson: Lesson
    let isDone: Bool
    let isNext: Bool

    private var difficulty: ChallengeDifficulty? { lesson.challenge.difficulty }

    private var difficultyColor: Color {
        switch difficulty {
        case .easy:      return Color(red: 0.20, green: 0.78, blue: 0.35)
        case .hard:      return Color(red: 0.98, green: 0.60, blue: 0.10)
        case .superHard: return Color(red: 0.92, green: 0.22, blue: 0.22)
        case nil:        return Color(red: 0.20, green: 0.78, blue: 0.35)
        }
    }

    private var difficultyLabel: String {
        switch difficulty {
        case .easy:      return "Easy"
        case .hard:      return "Hard"
        case .superHard: return "Super Hard"
        case nil:        return "Easy"
        }
    }

    private var isLocked: Bool { !isDone && !isNext }

    var body: some View {
        VStack(spacing: 8) {
            // Number badge
            ZStack {
                Circle()
                    .fill(tileBackground)
                    .frame(width: 52, height: 52)
                    .overlay(
                        Circle()
                            .strokeBorder(tileBorder, lineWidth: isNext ? 2.5 : 1.5)
                    )

                if isDone {
                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                } else if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color(.tertiaryLabel))
                } else {
                    Text("\(lesson.order)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }

            // Title (truncated)
            Text(lesson.title)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(isLocked ? Color(.tertiaryLabel) : Color(.label))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)

            // Difficulty pip
            if !isLocked {
                Text(difficultyLabel)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(difficultyColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(difficultyColor.opacity(0.15), in: Capsule())
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(.background, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: isNext ? difficultyColor.opacity(0.3) : .clear, radius: 6, y: 3)
        .opacity(isLocked ? 0.45 : 1.0)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityAddTraits(isLocked ? .isStaticText : .isButton)
    }

    private var tileBackground: Color {
        if isDone      { return Color(red: 0.20, green: 0.78, blue: 0.35) }
        if isNext      { return Color(red: 0.22, green: 0.45, blue: 0.90) }
        return Color(.quaternarySystemFill)
    }

    private var tileBorder: Color {
        if isDone      { return Color(red: 0.12, green: 0.62, blue: 0.25) }
        if isNext      { return Color(red: 0.22, green: 0.45, blue: 0.90) }
        return Color(.separator)
    }

    private var accessibilityLabel: String {
        let status = isDone ? "completed" : isNext ? "available" : "locked"
        return "Challenge \(lesson.order): \(lesson.title), \(difficultyLabel), \(status)"
    }
}

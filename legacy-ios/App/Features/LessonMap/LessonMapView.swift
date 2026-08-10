import SwiftUI
import ForgeCodeEngine

/// Displays the Code Basics lesson path: a vertical list of lesson nodes,
/// locked/unlocked based on the kid's `completedLessonIDs`. Tapping an
/// unlocked lesson opens the Lesson / Simulator screen.
struct LessonMapView: View {
    let kid: Kid
    let progressService: ProgressService

    @State private var selectedLesson: Lesson?
    private let store = LessonStore.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    lessonPath
                }
                .padding(.vertical, 24)
                .padding(.horizontal, 20)
            }
            .navigationTitle("Code Basics")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .navigationDestination(item: $selectedLesson) { lesson in
                LessonView(
                    lesson: lesson,
                    kid: kid,
                    progressService: progressService,
                    onComplete: { handleCompletion(of: lesson) }
                )
            }
        }
    }

    // MARK: - Subviews

    private var headerSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "flame.fill")
                .foregroundStyle(.orange)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text("Day streak: \(kid.currentStreak)")
                    .font(.headline)
                Text("Keep it up!")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(16)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Day streak: \(kid.currentStreak). Keep it up!")
    }

    private var lessonPath: some View {
        VStack(spacing: 16) {
            ForEach(store.codeBasicsLessons) { lesson in
                let isCompleted = kid.completedLessonIDs.contains(lesson.id)
                let isUnlocked = isLessonUnlocked(lesson)
                LessonNodeView(
                    lesson: lesson,
                    isUnlocked: isUnlocked,
                    isCompleted: isCompleted,
                    onTap: { if isUnlocked { selectedLesson = lesson } }
                )
            }
        }
    }

    // MARK: - Logic

    /// A lesson is unlocked if it's the first, or if the previous lesson is completed.
    private func isLessonUnlocked(_ lesson: Lesson) -> Bool {
        let lessons = store.codeBasicsLessons
        guard let index = lessons.firstIndex(where: { $0.id == lesson.id }) else {
            return false
        }
        if index == 0 { return true }
        let previous = lessons[index - 1]
        return kid.completedLessonIDs.contains(previous.id)
    }

    private func handleCompletion(of lesson: Lesson) {
        selectedLesson = nil
    }
}

// MARK: - Lesson node

struct LessonNodeView: View {
    let lesson: Lesson
    let isUnlocked: Bool
    let isCompleted: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                nodeIcon
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.headline)
                        .foregroundStyle(isUnlocked ? .primary : .secondary)
                    Text(lesson.goalDescription)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
                Spacer()

                if isUnlocked && !isCompleted {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(16)
            .background(.background, in: RoundedRectangle(cornerRadius: 12))
            .opacity(isUnlocked ? 1.0 : 0.5)
        }
        .buttonStyle(.plain)
        .disabled(!isUnlocked)
        .accessibilityLabel(nodeAccessibilityLabel)
        .accessibilityHint(isUnlocked && !isCompleted ? "Tap to start this lesson." : "")
    }

    private var nodeIcon: some View {
        ZStack {
            Circle()
                .fill(nodeColor.opacity(0.15))
            Image(systemName: nodeSystemImage)
                .font(.system(size: 28))
                .foregroundStyle(nodeColor)
        }
    }

    private var nodeSystemImage: String {
        if isCompleted { return "checkmark.seal.fill" }
        if isUnlocked { return "play.circle.fill" }
        return "lock.fill"
    }

    private var nodeColor: Color {
        if isCompleted { return .green }
        if isUnlocked { return .accentColor }
        return .gray
    }

    private var nodeAccessibilityLabel: String {
        let status = isCompleted ? "Completed" : isUnlocked ? "Unlocked" : "Locked"
        return "\(lesson.title). \(status). \(lesson.goalDescription)"
    }
}

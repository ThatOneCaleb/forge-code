import SwiftUI
import SwiftData

/// The Build Log: a reverse-chronological list of the kid's reflective entries.
/// Always accessible from the tab bar — not gated by lesson progress.
struct BuildLogListView: View {
    let kid: Kid
    let progressService: ProgressService

    @Query(sort: \BuildLogEntry.date, order: .reverse) private var entries: [BuildLogEntry]
    @State private var showAddEntry = false

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    entryList
                }
            }
            .navigationTitle("Build Log")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .frame(minWidth: 44, minHeight: 44)
                    .accessibilityLabel("Add Build Log entry")
                }
            }
            .sheet(isPresented: $showAddEntry) {
                AddBuildLogEntryView(kid: kid, progressService: progressService, isPresented: $showAddEntry)
            }
        }
    }

    // MARK: - Subviews

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 56))
                .foregroundStyle(.secondary)
            Text("No entries yet")
                .font(.title3.bold())
            Text("After completing a lesson, add a note about what you learned!")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Button("Add First Entry") {
                showAddEntry = true
            }
            .buttonStyle(.borderedProminent)
            .frame(minHeight: 44)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
    }

    private var entryList: some View {
        List {
            ForEach(entries) { entry in
                BuildLogRowView(entry: entry, progressService: progressService)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
            }
        }
        .listStyle(.plain)
    }
}

/// A single Build Log entry row.
struct BuildLogRowView: View {
    let entry: BuildLogEntry
    let progressService: ProgressService

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                photoThumbnail
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        TagChip(tag: entry.tag)
                        Spacer()
                        Text(Self.dateFormatter.string(from: entry.date))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !entry.noteText.isEmpty {
                        Text(entry.noteText)
                            .font(.body)
                            .lineLimit(3)
                    }
                }
            }
        }
        .padding(14)
        .background(.background, in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(rowAccessibilityLabel)
    }

    @ViewBuilder
    private var photoThumbnail: some View {
        if let filename = entry.photoFilename,
           let data = progressService.loadPhoto(filename: filename),
           let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray5))
                .overlay {
                    Image(systemName: "doc.text.fill")
                        .foregroundStyle(Color(.systemGray3))
                }
        }
    }

    private var rowAccessibilityLabel: String {
        let dateStr = Self.dateFormatter.string(from: entry.date)
        let note = entry.noteText.isEmpty ? "No note." : entry.noteText
        return "\(entry.tag.displayName) entry on \(dateStr). \(note)"
    }
}

/// Small coloured tag chip.
struct TagChip: View {
    let tag: BuildLogTag

    var body: some View {
        Text(tag.displayName)
            .font(.caption.bold())
            .foregroundStyle(tagColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(tagColor.opacity(0.15), in: Capsule())
    }

    private var tagColor: Color {
        switch tag {
        case .coding:   return .blue
        case .robotics: return .green
        case .other:    return .secondary
        }
    }
}

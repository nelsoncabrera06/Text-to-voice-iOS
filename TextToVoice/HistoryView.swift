import SwiftUI

struct HistoryView: View {
    @ObservedObject var speechManager: SpeechManager
    @ObservedObject var historyManager: HistoryManager

    @State private var showDeleteAlert = false
    @State private var selectedItem: SavedItem?

    var body: some View {
        NavigationView {
            Group {
                if historyManager.savedItems.isEmpty {
                    emptyHistoryView
                } else {
                    historyList
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !historyManager.savedItems.isEmpty {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Clear", systemImage: "trash")
                    }
                }
            }
            .alert("Clear History", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Clear All", role: .destructive) {
                    historyManager.clearHistory()
                }
            } message: {
                Text("Are you sure you want to delete all history?")
            }
        }
    }

    // MARK: - Empty History View

    private var emptyHistoryView: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 70))
                .foregroundColor(.gray)

            Text("No History")
                .font(.title2)
                .foregroundColor(.secondary)

            Text("Texts you read will appear here")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }

    // MARK: - History List

    private var historyList: some View {
        List {
            ForEach(historyManager.savedItems) { item in
                HistoryItemRow(item: item)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        playItem(item)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            historyManager.deleteItem(item)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
    }

    // MARK: - Actions

    private func playItem(_ item: SavedItem) {
        speechManager.speak(text: item.content)
    }
}

// MARK: - History Item Row

struct HistoryItemRow: View {
    let item: SavedItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            Text(item.title)
                .font(.headline)
                .lineLimit(2)

            // Content preview
            Text(contentPreview)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Additional info
            HStack {
                if let url = item.sourceURL {
                    Label(url, systemImage: "link")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .lineLimit(1)
                }

                Spacer()

                Text(item.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private var contentPreview: String {
        let preview = item.content.prefix(100)
        return String(preview) + (item.content.count > 100 ? "..." : "")
    }
}

#Preview {
    let speechManager = SpeechManager()
    let historyManager = HistoryManager()

    // Add sample items
    historyManager.saveItem(SavedItem(
        content: "This is a sample text to test the history view.",
        sourceURL: "https://example.com"
    ))
    historyManager.saveItem(SavedItem(
        content: "Another test text without URL to demonstrate how the history looks with multiple items."
    ))

    return HistoryView(speechManager: speechManager, historyManager: historyManager)
}

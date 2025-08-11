import SwiftUI

struct CategoryEditView: View {
    let category: MetricCategory?
    let onSave: (String, String) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var emoji = ""
    @State private var showingEmojiPicker = false
    
    private var isEditing: Bool { category != nil }
    private var title: String { isEditing ? "Edit Category" : "Add Category" }
    private var saveButtonTitle: String { isEditing ? "Update" : "Add" }
    private var trimmedName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var isValidInput: Bool { !trimmedName.isEmpty && !emoji.isEmpty }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Category Details")) {
                    HStack {
                        Text("Name")
                        TextField("Enter category name", text: $name)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Emoji")
                        Spacer()
                        Button {
                            showingEmojiPicker = true
                        } label: {
                            Text(emoji.isEmpty ? "Select" : emoji)
                                .font(.title2)
                                .padding(8)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    }
                }
                
                if showingEmojiPicker {
                    Section(header: Text("Select Emoji")) {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 10) {
                            ForEach(Array(Self.commonEmojis.enumerated()), id: \.offset) { index, emojiOption in
                                Button(action: {
                                    emoji = emojiOption
                                    showingEmojiPicker = false
                                }) {
                                    Text(emojiOption)
                                        .font(.title2)
                                        .padding(8)
                                        .background(emoji == emojiOption ? Color.blue.opacity(0.3) : Color(.systemGray6))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(.vertical)
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(saveButtonTitle) {
                        onSave(trimmedName, emoji)
                        dismiss()
                    }
                    .disabled(!isValidInput)
                }
            }
            .onAppear {
                guard let category = category else { return }
                name = category.name
                emoji = category.emoji
            }
        }
    }
}

// MARK: - Constants
private extension CategoryEditView {
    static let commonEmojis = [
        "🏃‍♀️", "💼", "🌱", "👨‍👩‍👧‍👦", "❤️", "🧠", "💰", "🎯",
        "📚", "🎨", "🏠", "✈️", "🍎", "💪", "🧘‍♀️", "🎵",
        "⚽️", "🎮", "📱", "🚗", "🌟", "☀️", "🌙", "⚡️",
        "🔥", "💎", "🌊", "🏔️", "🌳", "🌺", "🦋", "🐾",
        "📈", "🎉", "🏆", "🎪", "🎭", "📝", "💡", "🔮",
        "⚙️", "🔧", "📊", "💻", "📞", "✉️", "🎁", "🍕"
    ]
}

#Preview {
    CategoryEditView(category: nil, onSave: { _, _ in })
}
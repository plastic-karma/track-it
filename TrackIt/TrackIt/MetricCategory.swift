import Foundation
import SwiftData

@Model
final class MetricCategory: Identifiable {
    var name: String
    var emoji: String
    var sortOrder: Int
    var isActive: Bool
    
    init(name: String, emoji: String, sortOrder: Int, isActive: Bool = true) {
        self.name = name
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.isActive = isActive
    }
    
    var displayTitle: String {
        "\(emoji) \(name)"
    }
    
    static func insertDefaultCategories(into context: ModelContext) {
        let defaults = [
            MetricCategory(name: "Health", emoji: "🏃‍♀️", sortOrder: 0),
            MetricCategory(name: "Work", emoji: "💼", sortOrder: 1),
            MetricCategory(name: "Growth", emoji: "🌱", sortOrder: 2),
            MetricCategory(name: "Family", emoji: "👨‍👩‍👧‍👦", sortOrder: 3)
        ]
        
        defaults.forEach { context.insert($0) }
        
        guard (try? context.save()) != nil else {
            print("Failed to create default categories")
            return
        }
    }
}
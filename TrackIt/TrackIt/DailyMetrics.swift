import Foundation
import SwiftData

@Model
final class DailyMetrics {
    var date: Date
    var notes: String
    @Relationship(deleteRule: .cascade) var categoryMetrics = [CategoryMetric]()
    
    // Legacy properties for backward compatibility during migration
    var healthRating: Int = 0
    var workRating: Int = 0
    var growthRating: Int = 0
    var familyRating: Int = 0
    
    init(date: Date, notes: String = "") {
        self.date = date
        self.notes = notes
    }
    
    // Legacy initializer for backward compatibility
    init(date: Date, healthRating: Int, workRating: Int, growthRating: Int, familyRating: Int, notes: String = "") {
        self.date = date
        self.notes = notes
        self.healthRating = healthRating
        self.workRating = workRating
        self.growthRating = growthRating
        self.familyRating = familyRating
    }
    
    var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    func getMetric(for categoryName: String) -> Int {
        // First try to find in new categoryMetrics
        if let categoryMetric = categoryMetrics.first(where: { $0.categoryName == categoryName }) {
            return categoryMetric.value
        }
        
        // Fallback to legacy properties for migration
        switch categoryName {
        case "Health": return healthRating
        case "Work": return workRating
        case "Growth": return growthRating
        case "Family": return familyRating
        default: return 0
        }
    }
    
    func setMetric(_ value: Int, for categoryName: String) {
        if let existingMetric = categoryMetrics.first(where: { $0.categoryName == categoryName }) {
            existingMetric.value = value
        } else {
            let newMetric = CategoryMetric(categoryName: categoryName, value: value)
            newMetric.dailyMetrics = self
            categoryMetrics.append(newMetric)
        }
    }
}

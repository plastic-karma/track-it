import Foundation
import SwiftData

@Model
final class CategoryMetric {
    var categoryName: String
    var value: Int
    var dailyMetrics: DailyMetrics?
    
    init(categoryName: String, value: Int) {
        self.categoryName = categoryName
        self.value = value
    }
}

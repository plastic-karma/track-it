import Foundation
import SwiftData
import SwiftUI

@MainActor
class StatisticsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var statisticsData: [CategoryStatistics] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    private var modelContext: ModelContext
    
    // MARK: - Initialization
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // Internal method to update the model context after view initialization
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Data Access Methods
    func getActiveCategories() -> [MetricCategory] {
        let descriptor = FetchDescriptor<MetricCategory>(
            predicate: #Predicate<MetricCategory> { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            handleError(StatisticsError.fetchFailed("Failed to fetch categories: \(error.localizedDescription)"))
            return []
        }
    }
    
    func getAllMetrics() -> [DailyMetrics] {
        let descriptor = FetchDescriptor<DailyMetrics>()
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            handleError(StatisticsError.fetchFailed("Failed to fetch metrics: \(error.localizedDescription)"))
            return []
        }
    }
    
    // MARK: - Business Logic Methods
    func loadStatistics() {
        isLoading = true
        errorMessage = nil
        
        let activeCategories = getActiveCategories()
        let allMetrics = getAllMetrics()
        
        var newStatisticsData: [CategoryStatistics] = []
        
        for category in activeCategories {
            let totalAverage = calculateTotalAverage(for: category.name, metrics: allMetrics)
            let tenDayAverage = calculateRunningAverage(for: category.name, days: 10, metrics: allMetrics)
            let thirtyDayAverage = calculateRunningAverage(for: category.name, days: 30, metrics: allMetrics)
            
            let statistics = CategoryStatistics(
                category: category,
                totalAverage: totalAverage,
                tenDayAverage: tenDayAverage,
                thirtyDayAverage: thirtyDayAverage
            )
            
            newStatisticsData.append(statistics)
        }
        
        statisticsData = newStatisticsData
        isLoading = false
    }
    
    func calculateTotalAverage(for categoryName: String, metrics: [DailyMetrics]) -> Double {
        let categoryMetrics = metrics.map { $0.getMetric(for: categoryName) }
        guard !categoryMetrics.isEmpty else { return 0.0 }
        
        let sum = categoryMetrics.reduce(0, +)
        return Double(sum) / Double(categoryMetrics.count)
    }
    
    func calculateRunningAverage(for categoryName: String, days: Int, metrics: [DailyMetrics]) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return 0.0
        }
        
        let recentMetrics = metrics.filter { metric in
            metric.date >= startDate && metric.date <= endDate
        }
        
        guard !recentMetrics.isEmpty else { return 0.0 }
        
        let categoryValues = recentMetrics.map { $0.getMetric(for: categoryName) }
        let sum = categoryValues.reduce(0, +)
        return Double(sum) / Double(categoryValues.count)
    }
    
    // MARK: - Convenience Methods
    func getStatistics(for category: MetricCategory) -> CategoryStatistics? {
        return statisticsData.first { $0.category.name == category.name }
    }
    
    func refreshStatistics() {
        loadStatistics()
    }
    
    // MARK: - Error Handling
    private func handleError(_ error: StatisticsError) {
        errorMessage = error.localizedDescription
        print(error.localizedDescription)
    }
    
    // MARK: - Formatted Data
    func getFormattedStatistics() -> [FormattedCategoryStatistics] {
        return statisticsData.map { stats in
            FormattedCategoryStatistics(
                category: stats.category,
                totalAverage: String(format: "%.1f", stats.totalAverage),
                tenDayAverage: String(format: "%.1f", stats.tenDayAverage),
                thirtyDayAverage: String(format: "%.1f", stats.thirtyDayAverage),
                totalAverageEmoji: Int(stats.totalAverage.rounded()).metricEmoji,
                tenDayAverageEmoji: Int(stats.tenDayAverage.rounded()).metricEmoji,
                thirtyDayAverageEmoji: Int(stats.thirtyDayAverage.rounded()).metricEmoji
            )
        }
    }
}

// MARK: - Data Models
struct CategoryStatistics: Identifiable {
    let id = UUID()
    let category: MetricCategory
    let totalAverage: Double
    let tenDayAverage: Double
    let thirtyDayAverage: Double
}

struct FormattedCategoryStatistics: Identifiable {
    let id = UUID()
    let category: MetricCategory
    let totalAverage: String
    let tenDayAverage: String
    let thirtyDayAverage: String
    let totalAverageEmoji: String
    let tenDayAverageEmoji: String
    let thirtyDayAverageEmoji: String
}

// MARK: - Error Types
enum StatisticsError: LocalizedError {
    case fetchFailed(String)
    case calculationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .fetchFailed(let message):
            return "Data fetch error: \(message)"
        case .calculationFailed(let message):
            return "Calculation error: \(message)"
        }
    }
}

// MARK: - Factory
@MainActor
class StatisticsViewModelFactory {
    static func createEmpty() -> StatisticsViewModel {
        // Create a temporary empty model context for initialization
        do {
            let schema = Schema([DailyMetrics.self, MetricCategory.self, CategoryMetric.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            return StatisticsViewModel(modelContext: context)
        } catch {
            fatalError("Could not create temporary ModelContext: \(error)")
        }
    }
}

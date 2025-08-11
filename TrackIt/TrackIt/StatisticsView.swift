import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var metrics: [DailyMetrics]
    @Query(sort: \MetricCategory.sortOrder) private var categories: [MetricCategory]
    
    private var activeCategories: [MetricCategory] {
        categories.filter(\.isActive)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(activeCategories, id: \.name) { category in
                        StatisticCard(
                            category: category,
                            totalAverage: calculateTotalAverage(for: category.name),
                            tenDayAverage: calculateRunningAverage(for: category.name, days: 10),
                            thirtyDayAverage: calculateRunningAverage(for: category.name, days: 30)
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("📊 Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Statistics Calculations
private extension StatisticsView {
    func calculateTotalAverage(for categoryName: String) -> Double {
        let categoryMetrics = metrics.map { $0.getMetric(for: categoryName) }
        guard !categoryMetrics.isEmpty else { return 0.0 }
        
        let sum = categoryMetrics.reduce(0, +)
        return Double(sum) / Double(categoryMetrics.count)
    }
    
    func calculateRunningAverage(for categoryName: String, days: Int) -> Double {
        let calendar = Calendar.current
        let endDate = Date()
        let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) ?? endDate
        
        let recentMetrics = metrics.filter { metric in
            metric.date >= startDate && metric.date <= endDate
        }
        
        guard !recentMetrics.isEmpty else { return 0.0 }
        
        let categoryValues = recentMetrics.map { $0.getMetric(for: categoryName) }
        let sum = categoryValues.reduce(0, +)
        return Double(sum) / Double(categoryValues.count)
    }
}

// MARK: - Statistic Card Component
struct StatisticCard: View {
    let category: MetricCategory
    let totalAverage: Double
    let tenDayAverage: Double
    let thirtyDayAverage: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            // Category Header
            HStack {
                Text(category.displayTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Statistics Grid
            VStack(spacing: 12) {
                StatisticRow(
                    title: "Total Average",
                    value: totalAverage,
                    icon: "chart.line.uptrend.xyaxis"
                )
                
                StatisticRow(
                    title: "10-Day Average",
                    value: tenDayAverage,
                    icon: "calendar.badge.clock"
                )
                
                StatisticRow(
                    title: "30-Day Average",
                    value: thirtyDayAverage,
                    icon: "calendar.badge.clock"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Statistic Row Component
struct StatisticRow: View {
    let title: String
    let value: Double
    let icon: String
    
    private var roundedValue: Int { Int(value.rounded()) }
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .font(.title3)
                .frame(width: 24)
            
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Spacer()
            
            HStack(spacing: 8) {
                Text(roundedValue.metricEmoji)
                    .font(.title3)
                
                Text(String(format: "%.1f", value))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(roundedValue.metricColor)
            }
        }
    }
}

#Preview {
    StatisticsView()
        .modelContainer(for: [DailyMetrics.self, MetricCategory.self, CategoryMetric.self], inMemory: true)
}

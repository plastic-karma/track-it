import SwiftUI
import SwiftData

struct StatisticsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = StatisticsViewModelFactory.createEmpty()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if viewModel.isLoading {
                    ProgressView("Loading statistics...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Error Loading Statistics")
                            .font(.headline)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Button("Retry") {
                            viewModel.refreshStatistics()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                } else {
                    VStack(spacing: 20) {
                        ForEach(viewModel.statisticsData) { statistics in
                            StatisticCard(
                                category: statistics.category,
                                totalAverage: statistics.totalAverage,
                                tenDayAverage: statistics.tenDayAverage,
                                thirtyDayAverage: statistics.thirtyDayAverage
                            )
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("📊 Statistics")
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                viewModel.refreshStatistics()
            }
            .onAppear {
                viewModel.updateModelContext(modelContext)
                viewModel.loadStatistics()
            }
        }
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

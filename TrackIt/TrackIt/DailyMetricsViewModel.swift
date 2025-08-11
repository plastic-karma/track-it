import Foundation
import SwiftData
import SwiftUI

@MainActor
class DailyMetricsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var categoryMetrics = [String: Double]()
    @Published var notes = ""
    @Published var selectedDate = Date()
    @Published var isEditingMode = false
    @Published var activeCategories: [MetricCategory] = []
    
    // MARK: - Dependencies
    private var modelContext: ModelContext
    private let notificationManager: NotificationManager
    
    // MARK: - Computed Properties
    var isSelectedDateToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    // MARK: - Initialization
    init(modelContext: ModelContext, notificationManager: NotificationManager? = nil) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager ?? NotificationManager.shared
    }
    
    // Internal method to update the model context after view initialization
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadActiveCategories()
    }
    
    // MARK: - Data Access Methods
    func loadActiveCategories() {
        let descriptor = FetchDescriptor<MetricCategory>(
            predicate: #Predicate<MetricCategory> { $0.isActive == true },
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        do {
            activeCategories = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch active categories: \(error)")
            activeCategories = []
        }
    }
    
    func getMetricsForDate(_ date: Date) -> DailyMetrics? {
        let descriptor = FetchDescriptor<DailyMetrics>()
        
        do {
            let allMetrics = try modelContext.fetch(descriptor)
            return allMetrics.first { Calendar.current.isDate($0.date, inSameDayAs: date) }
        } catch {
            print("Failed to fetch metrics for date: \(error)")
            return nil
        }
    }
    
    func getAllMetrics() -> [DailyMetrics] {
        let descriptor = FetchDescriptor<DailyMetrics>()
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            print("Failed to fetch all metrics: \(error)")
            return []
        }
    }
    
    // MARK: - Business Logic Methods
    func saveMetrics() throws {
        let newMetrics = DailyMetrics(date: selectedDate, notes: notes)
        modelContext.insert(newMetrics)
        
        // Set values for each category
        for category in activeCategories {
            let value = Int(categoryMetrics[category.name] ?? 0.0)
            newMetrics.setMetric(value, for: category.name)
        }
        
        try modelContext.save()
        resetFormFields()
    }
    
    func updateMetrics(_ metrics: DailyMetrics) throws {
        // Update values for each category
        for category in activeCategories {
            let value = Int(categoryMetrics[category.name] ?? 0.0)
            metrics.setMetric(value, for: category.name)
        }
        metrics.notes = notes
        
        try modelContext.save()
    }
    
    func enterEditMode(for metrics: DailyMetrics) {
        categoryMetrics.removeAll()
        
        for category in activeCategories {
            categoryMetrics[category.name] = Double(metrics.getMetric(for: category.name))
        }
        notes = metrics.notes
        isEditingMode = true
    }
    
    func cancelEditMode() {
        isEditingMode = false
        resetFormFields()
    }
    
    func resetFormFields() {
        categoryMetrics.removeAll()
        notes = ""
    }
    
    func navigateToDate(_ date: Date) {
        selectedDate = date
        exitEditModeIfNeeded()
    }
    
    func navigateDate(by days: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) {
            selectedDate = newDate
            exitEditModeIfNeeded()
        }
    }
    
    func navigateToToday() {
        selectedDate = Date()
        exitEditModeIfNeeded()
    }
    
    private func exitEditModeIfNeeded() {
        guard isEditingMode else { return }
        isEditingMode = false
        resetFormFields()
    }
    
    // MARK: - Initialization Methods
    func initializeNotifications() {
        let settings = AppSettings.getOrCreate(context: modelContext)
        guard settings.notificationsEnabled else { return }
        notificationManager.scheduleDailyNotification(
            at: settings.notificationTime,
            enabled: settings.notificationsEnabled
        )
    }
    
    func ensureDefaultCategories() {
        guard activeCategories.isEmpty else { return }
        MetricCategory.insertDefaultCategories(into: modelContext)
        loadActiveCategories()
    }
    
    // MARK: - Validation Methods
    func isValidForSaving() -> Bool {
        return !categoryMetrics.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    func hasUnsavedChanges() -> Bool {
        return !categoryMetrics.isEmpty || !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Binding Helpers
    func categoryMetricBinding(for categoryName: String) -> Binding<Double> {
        Binding(
            get: { self.categoryMetrics[categoryName] ?? 0.0 },
            set: { self.categoryMetrics[categoryName] = $0 }
        )
    }
    
    func notesBinding() -> Binding<String> {
        Binding(
            get: { self.notes },
            set: { self.notes = $0 }
        )
    }
}

// MARK: - Error Types
enum DailyMetricsError: LocalizedError {
    case saveFailed(String)
    case updateFailed(String)
    case fetchFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save metrics: \(message)"
        case .updateFailed(let message):
            return "Failed to update metrics: \(message)"
        case .fetchFailed(let message):
            return "Failed to fetch data: \(message)"
        }
    }
}

// MARK: - Factory
@MainActor
class DailyMetricsViewModelFactory {
    static func createEmpty() -> DailyMetricsViewModel {
        // Create a temporary empty model context for initialization
        // This will be replaced with the real context in onAppear
        do {
            let schema = Schema([DailyMetrics.self, MetricCategory.self, CategoryMetric.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            return DailyMetricsViewModel(modelContext: context)
        } catch {
            fatalError("Could not create temporary ModelContext: \(error)")
        }
    }
}

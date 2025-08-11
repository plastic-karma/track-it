import Foundation
import SwiftData
import SwiftUI

@MainActor
class SettingsViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var settings: AppSettings?
    @Published var showingPermissionAlert = false
    @Published var showingAddCategory = false
    @Published var editingCategory: MetricCategory?
    @Published var categories: [MetricCategory] = []
    
    // MARK: - Dependencies
    private var modelContext: ModelContext
    private let notificationManager: NotificationManager
    
    // MARK: - Initialization
    init(modelContext: ModelContext, notificationManager: NotificationManager? = nil) {
        self.modelContext = modelContext
        self.notificationManager = notificationManager ?? NotificationManager.shared
    }
    
    // Internal method to update the model context after view initialization
    func updateModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadSettings()
        loadCategories()
    }
    
    // MARK: - Data Access Methods
    func loadSettings() {
        settings = AppSettings.getOrCreate(context: modelContext)
    }
    
    func loadCategories() {
        let descriptor = FetchDescriptor<MetricCategory>(
            sortBy: [SortDescriptor(\.sortOrder)]
        )
        
        do {
            categories = try modelContext.fetch(descriptor)
        } catch {
            print("Failed to load categories: \(error)")
            categories = []
        }
    }
    
    var activeCategories: [MetricCategory] {
        categories.filter(\.isActive)
    }
    
    // MARK: - Settings Management
    func saveSettings() throws {
        try modelContext.save()
    }
    
    // MARK: - Notification Management
    func handleNotificationToggle(_ enabled: Bool) {
        if enabled && !notificationManager.hasPermission {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    if granted {
                        settings?.notificationsEnabled = true
                        try? saveSettings()
                        updateNotificationSchedule()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            settings?.notificationsEnabled = enabled
            try? saveSettings()
            updateNotificationSchedule()
        }
    }
    
    func updateNotificationSchedule() {
        guard let settings = settings else { return }
        notificationManager.scheduleDailyNotification(
            at: settings.notificationTime,
            enabled: settings.notificationsEnabled
        )
    }
    
    func handleWeeklyStatsToggle(_ enabled: Bool) {
        if enabled && !notificationManager.hasPermission {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    if granted {
                        settings?.weeklyStatsReminderEnabled = true
                        try? saveSettings()
                        updateWeeklyStatsSchedule()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            settings?.weeklyStatsReminderEnabled = enabled
            try? saveSettings()
            updateWeeklyStatsSchedule()
        }
    }
    
    func updateWeeklyStatsSchedule() {
        guard let settings = settings else { return }
        notificationManager.scheduleWeeklyStatsReminder(
            day: settings.weeklyStatsReminderDay,
            time: settings.weeklyStatsReminderTime,
            enabled: settings.weeklyStatsReminderEnabled
        )
    }
    
    // MARK: - Category Management
    func ensureDefaultCategories() {
        guard categories.isEmpty else { return }
        MetricCategory.insertDefaultCategories(into: modelContext)
        loadCategories()
    }
    
    func addCategory(name: String, emoji: String) throws {
        let maxOrder = categories.map(\.sortOrder).max() ?? -1
        let newCategory = MetricCategory(
            name: name,
            emoji: emoji,
            sortOrder: maxOrder + 1
        )
        modelContext.insert(newCategory)
        try saveSettings()
        loadCategories()
    }
    
    func updateCategory(_ category: MetricCategory, name: String, emoji: String) throws {
        category.name = name
        category.emoji = emoji
        try saveSettings()
        loadCategories()
    }
    
    func deleteCategories(at offsets: IndexSet) throws {
        for index in offsets {
            let category = activeCategories[index]
            category.isActive = false
        }
        try saveSettings()
        loadCategories()
    }
    
    func moveCategories(from source: IndexSet, to destination: Int) throws {
        var activeCategoriesCopy = activeCategories
        activeCategoriesCopy.move(fromOffsets: source, toOffset: destination)
        
        for (index, category) in activeCategoriesCopy.enumerated() {
            category.sortOrder = index
        }
        try saveSettings()
        loadCategories()
    }
    
    // MARK: - Category Edit Actions
    func startEditingCategory(_ category: MetricCategory) {
        editingCategory = category
    }
    
    func startAddingCategory() {
        showingAddCategory = true
    }
    
    func dismissPermissionAlert() {
        showingPermissionAlert = false
        settings?.notificationsEnabled = false
        try? saveSettings()
    }
    
    func openSystemSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    // MARK: - Binding Helpers
    func notificationEnabledBinding() -> Binding<Bool> {
        Binding(
            get: { self.settings?.notificationsEnabled ?? false },
            set: { self.handleNotificationToggle($0) }
        )
    }
    
    func notificationTimeBinding() -> Binding<Date> {
        Binding(
            get: { self.settings?.notificationTime ?? Date() },
            set: { newTime in
                self.settings?.notificationTime = newTime
                try? self.saveSettings()
                self.updateNotificationSchedule()
            }
        )
    }
    
    func weeklyStatsEnabledBinding() -> Binding<Bool> {
        Binding(
            get: { self.settings?.weeklyStatsReminderEnabled ?? false },
            set: { self.handleWeeklyStatsToggle($0) }
        )
    }
    
    func weeklyStatsDayBinding() -> Binding<Int> {
        Binding(
            get: { self.settings?.weeklyStatsReminderDay ?? 1 },
            set: { newDay in
                self.settings?.weeklyStatsReminderDay = newDay
                try? self.saveSettings()
                self.updateWeeklyStatsSchedule()
            }
        )
    }
    
    func weeklyStatsTimeBinding() -> Binding<Date> {
        Binding(
            get: { self.settings?.weeklyStatsReminderTime ?? Date() },
            set: { newTime in
                self.settings?.weeklyStatsReminderTime = newTime
                try? self.saveSettings()
                self.updateWeeklyStatsSchedule()
            }
        )
    }
    
    // MARK: - Computed Properties
    var isNotificationEnabled: Bool {
        settings?.notificationsEnabled ?? false
    }
    
    var isWeeklyStatsEnabled: Bool {
        settings?.weeklyStatsReminderEnabled ?? false
    }
    
    var notificationTime: Date {
        settings?.notificationTime ?? Date()
    }
    
    var weeklyStatsDay: Int {
        settings?.weeklyStatsReminderDay ?? 1
    }
    
    var weeklyStatsTime: Date {
        settings?.weeklyStatsReminderTime ?? Date()
    }
}

// MARK: - Error Types
enum SettingsError: LocalizedError {
    case saveFailed(String)
    case loadFailed(String)
    case categoryManagementFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let message):
            return "Failed to save settings: \(message)"
        case .loadFailed(let message):
            return "Failed to load settings: \(message)"
        case .categoryManagementFailed(let message):
            return "Category management error: \(message)"
        }
    }
}

// MARK: - Factory
@MainActor
class SettingsViewModelFactory {
    static func createEmpty() -> SettingsViewModel {
        // Create a temporary empty model context for initialization
        do {
            let schema = Schema([AppSettings.self, MetricCategory.self, DailyMetrics.self, CategoryMetric.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let context = ModelContext(container)
            return SettingsViewModel(modelContext: context)
        } catch {
            fatalError("Could not create temporary ModelContext: \(error)")
        }
    }
}

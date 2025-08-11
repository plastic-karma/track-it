import Foundation
import SwiftData

@Model
final class AppSettings {
    var notificationsEnabled: Bool
    var notificationTime: Date
    private var weeklyStatsReminderEnabledStorage: Bool?
    private var weeklyStatsReminderDayStorage: Int? // 1 = Sunday, 2 = Monday, etc.
    private var weeklyStatsReminderTimeStorage: Date?
    
    // Computed properties with default values for backward compatibility
    var weeklyStatsReminderEnabled: Bool {
        get { weeklyStatsReminderEnabledStorage ?? false }
        set { weeklyStatsReminderEnabledStorage = newValue }
    }
    
    var weeklyStatsReminderDay: Int {
        get { weeklyStatsReminderDayStorage ?? 1 } // Default to Sunday
        set { weeklyStatsReminderDayStorage = newValue }
    }
    
    var weeklyStatsReminderTime: Date {
        get {
            weeklyStatsReminderTimeStorage ??
            (Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date())
        }
        set { weeklyStatsReminderTimeStorage = newValue }
    }
    
    init(
        notificationsEnabled: Bool = false,
        notificationTime: Date = Calendar.current.date(
            bySettingHour: 20, minute: 0, second: 0, of: Date()
        ) ?? Date(),
        weeklyStatsReminderEnabled: Bool = false,
        weeklyStatsReminderDay: Int = 1,
        weeklyStatsReminderTime: Date = Calendar.current.date(
            bySettingHour: 10, minute: 0, second: 0, of: Date()
        ) ?? Date()
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.notificationTime = notificationTime
        self.weeklyStatsReminderEnabledStorage = weeklyStatsReminderEnabled
        self.weeklyStatsReminderDayStorage = weeklyStatsReminderDay
        self.weeklyStatsReminderTimeStorage = weeklyStatsReminderTime
    }
    
    static func getOrCreate(context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        do {
            if let existing = try context.fetch(descriptor).first {
                return existing
            } else {
                let newSettings = AppSettings()
                context.insert(newSettings)
                try? context.save()
                return newSettings
            }
        } catch {
            print("Failed to fetch AppSettings, creating new ones: \(error)")
            let newSettings = AppSettings()
            context.insert(newSettings)
            try? context.save()
            return newSettings
        }
    }
}

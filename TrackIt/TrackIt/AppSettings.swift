import Foundation
import SwiftData

@Model
final class AppSettings {
    var notificationsEnabled: Bool
    var notificationTime: Date
    var _weeklyStatsReminderEnabled: Bool?
    var _weeklyStatsReminderDay: Int? // 1 = Sunday, 2 = Monday, etc.
    var _weeklyStatsReminderTime: Date?
    
    // Computed properties with default values for backward compatibility
    var weeklyStatsReminderEnabled: Bool {
        get { _weeklyStatsReminderEnabled ?? false }
        set { _weeklyStatsReminderEnabled = newValue }
    }
    
    var weeklyStatsReminderDay: Int {
        get { _weeklyStatsReminderDay ?? 1 } // Default to Sunday
        set { _weeklyStatsReminderDay = newValue }
    }
    
    var weeklyStatsReminderTime: Date {
        get { _weeklyStatsReminderTime ?? (Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()) }
        set { _weeklyStatsReminderTime = newValue }
    }
    
    init(
        notificationsEnabled: Bool = false, 
        notificationTime: Date = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date()) ?? Date(),
        weeklyStatsReminderEnabled: Bool = false,
        weeklyStatsReminderDay: Int = 1,
        weeklyStatsReminderTime: Date = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date()) ?? Date()
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.notificationTime = notificationTime
        self._weeklyStatsReminderEnabled = weeklyStatsReminderEnabled
        self._weeklyStatsReminderDay = weeklyStatsReminderDay
        self._weeklyStatsReminderTime = weeklyStatsReminderTime
    }
    
    static func getOrCreate(context: ModelContext) -> AppSettings {
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        } else {
            let newSettings = AppSettings()
            context.insert(newSettings)
            return newSettings
        }
    }
}
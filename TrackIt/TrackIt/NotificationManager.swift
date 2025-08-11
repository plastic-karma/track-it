import Foundation
import UserNotifications

@MainActor
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    
    @Published var hasPermission = false
    
    init() {
        Task {
            await getAuthorizationStatus()
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            hasPermission = granted
            return granted
        } catch {
            print("Failed to request notification authorization: \(error)")
            hasPermission = false
            return false
        }
    }
    
    func getAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        hasPermission = settings.authorizationStatus == .authorized
    }
    
    func scheduleDailyNotification(at time: Date, enabled: Bool) {
        // Remove existing notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-metrics"])
        
        guard enabled && hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Daily Metrics"
        content.body = "Track your daily performance! Record metrics for health, work, growth, and family."
        content.sound = .default
        content.userInfo = ["type": "daily-metrics"]
        
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: "daily-metrics", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }
    
    func cancelDailyNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily-metrics"])
    }
    
    func scheduleWeeklyStatsReminder(day: Int, time: Date, enabled: Bool) {
        // Remove existing weekly notification
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-stats"])
        
        guard enabled && hasPermission else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Weekly Stats Review"
        content.body = "Take a look at your weekly progress and see how you're doing!"
        content.sound = .default
        content.userInfo = ["type": "weekly-stats"]
        
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        
        // Create date components for the weekly trigger
        var dateComponents = DateComponents()
        dateComponents.weekday = day // 1 = Sunday, 2 = Monday, etc.
        dateComponents.hour = timeComponents.hour
        dateComponents.minute = timeComponents.minute
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        let request = UNNotificationRequest(identifier: "weekly-stats", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                print("Failed to schedule weekly stats notification: \(error)")
            }
        }
    }
    
    func cancelWeeklyStatsReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["weekly-stats"])
    }
}
import SwiftUI
import UserNotifications

class AppNavigationState: ObservableObject {
    @Published var showStatistics = false
    
    func navigateToStatistics() {
        showStatistics = true
    }
}

struct ContentView: View {
    @StateObject private var navigationState = AppNavigationState()
    
    var body: some View {
        NavigationStack {
            DailyMetricsView()
        }
        .fullScreenCover(isPresented: $navigationState.showStatistics) {
            NavigationStack {
                StatisticsView()
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") {
                                navigationState.showStatistics = false
                            }
                        }
                    }
            }
        }
        .environmentObject(navigationState)
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkForNotificationResponse()
        }
    }
    
    private func checkForNotificationResponse() {
        // Check if app was opened from a notification
        UNUserNotificationCenter.current().getDeliveredNotifications { _ in
            // This approach works for when the app is in background/foreground
            // For a more robust solution, we'd need to implement UNUserNotificationCenterDelegate
        }
    }
}

// MARK: - Notification Handling
class NotificationDelegate: NSObject, ObservableObject {
    static let shared = NotificationDelegate()
    
    weak var navigationState: AppNavigationState?
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        
        let userInfo = response.notification.request.content.userInfo
        
        if let type = userInfo["type"] as? String, type == "weekly-stats" {
            DispatchQueue.main.async { [weak self] in
                self?.navigationState?.navigateToStatistics()
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound, .badge])
    }
}

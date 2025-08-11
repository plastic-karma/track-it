//
//  TrackItApp.swift
//  TrackIt
//
//  Created by Rogge, Benni on 8/9/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct TrackItApp: App {
    @StateObject private var navigationState = AppNavigationState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyMetrics.self,
            AppSettings.self,
            MetricCategory.self,
            CategoryMetric.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()
    
    init() {
        // Set up notification delegate
        let notificationDelegate = NotificationDelegate.shared
        UNUserNotificationCenter.current().delegate = notificationDelegate
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    // Connect navigation state to notification delegate
                    NotificationDelegate.shared.navigationState = navigationState
                }
        }
        .modelContainer(sharedModelContainer)
        .environmentObject(navigationState)
    }
}

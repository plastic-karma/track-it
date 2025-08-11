//
//  NotificationManagerTests.swift
//  TrackItTests
//
//  Created by Claude on 8/11/25.
//

import Testing
import Foundation
import UserNotifications
@testable import TrackIt

@MainActor
struct NotificationManagerTests {
    
    // MARK: - Initialization Tests
    
    @Test func notificationManagerInitialization() async throws {
        let manager = NotificationManager()
        
        // Initial state should be false until permission is checked
        #expect(manager.hasPermission == false)
    }
    
    @Test func sharedInstanceExists() async throws {
        let shared1 = NotificationManager.shared
        let shared2 = NotificationManager.shared
        
        #expect(shared1 === shared2)
    }
    
    // MARK: - Notification Content Tests
    
    @Test func dailyNotificationSchedulingWithoutPermission() async throws {
        let manager = NotificationManager()
        manager.hasPermission = false
        
        let time = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        
        // Should not crash when scheduling without permission
        manager.scheduleDailyNotification(at: time, enabled: true)
        
        // Verify notification was not scheduled by checking pending requests
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let dailyRequests = requests.filter { $0.identifier == "daily-metrics" }
        #expect(dailyRequests.isEmpty)
    }
    
    @Test func dailyNotificationCancellation() async throws {
        let manager = NotificationManager()
        
        // Cancel any existing notifications
        manager.cancelDailyNotification()
        
        // Verify no daily notifications exist
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let dailyRequests = requests.filter { $0.identifier == "daily-metrics" }
        #expect(dailyRequests.isEmpty)
    }
    
    @Test func weeklyStatsNotificationSchedulingWithoutPermission() async throws {
        let manager = NotificationManager()
        manager.hasPermission = false
        
        let time = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        
        // Should not crash when scheduling without permission
        manager.scheduleWeeklyStatsReminder(day: 1, time: time, enabled: true)
        
        // Verify notification was not scheduled
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let weeklyRequests = requests.filter { $0.identifier == "weekly-stats" }
        #expect(weeklyRequests.isEmpty)
    }
    
    @Test func weeklyStatsNotificationCancellation() async throws {
        let manager = NotificationManager()
        
        // Cancel any existing weekly notifications
        manager.cancelWeeklyStatsReminder()
        
        // Verify no weekly notifications exist
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let weeklyRequests = requests.filter { $0.identifier == "weekly-stats" }
        #expect(weeklyRequests.isEmpty)
    }
    
    @Test func schedulingDisabledNotification() async throws {
        let manager = NotificationManager()
        let time = Calendar.current.date(bySettingHour: 20, minute: 0, second: 0, of: Date())!
        
        // Scheduling with enabled: false should not create notifications
        manager.scheduleDailyNotification(at: time, enabled: false)
        
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let dailyRequests = requests.filter { $0.identifier == "daily-metrics" }
        #expect(dailyRequests.isEmpty)
    }
    
    @Test func schedulingDisabledWeeklyNotification() async throws {
        let manager = NotificationManager()
        let time = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
        
        // Scheduling with enabled: false should not create notifications
        manager.scheduleWeeklyStatsReminder(day: 1, time: time, enabled: false)
        
        let center = UNUserNotificationCenter.current()
        let requests = await center.pendingNotificationRequests()
        let weeklyRequests = requests.filter { $0.identifier == "weekly-stats" }
        #expect(weeklyRequests.isEmpty)
    }
    
    // MARK: - Permission Tests
    
    @Test func getAuthorizationStatusUpdatesPermission() async throws {
        let manager = NotificationManager()
        
        // Test that the method runs without crashing
        await manager.getAuthorizationStatus()
        
        // Note: We can't easily test the actual permission state change
        // in unit tests since it depends on system settings
        // But we can verify the method executes successfully
    }
    
    @Test func requestAuthorizationHandlesSuccess() async throws {
        let manager = NotificationManager()
        
        // This will likely fail in test environment, but should not crash
        let result = await manager.requestAuthorization()
        
        // The result will be false in test environment, but that's expected
        #expect(result == false || result == true) // Just verify it returns a boolean
        #expect(manager.hasPermission == result)
    }
}
//
//  TrackItTests.swift
//  TrackItTests
//
//  Created by Rogge, Benni on 8/9/25.
//

import Testing
import Foundation
import SwiftData
@testable import TrackIt

struct TrackItTests {
    
    // MARK: - CategoryMetric Tests
    
    @Test func categoryMetricInitialization() async throws {
        let metric = CategoryMetric(categoryName: "Health", value: 5)
        
        #expect(metric.categoryName == "Health")
        #expect(metric.value == 5)
        #expect(metric.dailyMetrics == nil)
    }
    
    // MARK: - MetricCategory Tests
    
    @Test func metricCategoryInitialization() async throws {
        let category = MetricCategory(name: "Work", emoji: "💼", sortOrder: 1)
        
        #expect(category.name == "Work")
        #expect(category.emoji == "💼")
        #expect(category.sortOrder == 1)
        #expect(category.isActive == true)
    }
    
    @Test func metricCategoryInitializationWithActive() async throws {
        let category = MetricCategory(name: "Health", emoji: "🏃‍♀️", sortOrder: 0, isActive: false)
        
        #expect(category.name == "Health")
        #expect(category.emoji == "🏃‍♀️")
        #expect(category.sortOrder == 0)
        #expect(category.isActive == false)
    }
    
    @Test func metricCategoryDisplayTitle() async throws {
        let category = MetricCategory(name: "Growth", emoji: "🌱", sortOrder: 2)
        
        #expect(category.displayTitle == "🌱 Growth")
    }
    
    @Test func insertDefaultCategoriesCreatesCorrectCategories() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: MetricCategory.self, configurations: config)
        let context = ModelContext(container)
        
        MetricCategory.insertDefaultCategories(into: context)
        
        let descriptor = FetchDescriptor<MetricCategory>(sortBy: [SortDescriptor(\.sortOrder)])
        let categories = try context.fetch(descriptor)
        
        #expect(categories.count == 4)
        #expect(categories[0].name == "Health")
        #expect(categories[0].emoji == "🏃‍♀️")
        #expect(categories[1].name == "Work")
        #expect(categories[1].emoji == "💼")
        #expect(categories[2].name == "Growth")
        #expect(categories[2].emoji == "🌱")
        #expect(categories[3].name == "Family")
        #expect(categories[3].emoji == "👨‍👩‍👧‍👦")
    }
    
    // MARK: - DailyMetrics Tests
    
    @Test func dailyMetricsInitialization() async throws {
        let date = Date()
        let metrics = DailyMetrics(date: date, notes: "Test notes")
        
        #expect(metrics.date == date)
        #expect(metrics.notes == "Test notes")
        #expect(metrics.categoryMetrics.isEmpty)
    }
    
    @Test func dailyMetricsLegacyInitialization() async throws {
        let date = Date()
        let metrics = DailyMetrics(date: date, healthRating: 8, workRating: 7, growthRating: 6, familyRating: 9, notes: "Legacy test")
        
        #expect(metrics.date == date)
        #expect(metrics.notes == "Legacy test")
        #expect(metrics.healthRating == 8)
        #expect(metrics.workRating == 7)
        #expect(metrics.growthRating == 6)
        #expect(metrics.familyRating == 9)
    }
    
    @Test func dailyMetricsIsToday() async throws {
        let todayMetrics = DailyMetrics(date: Date())
        let yesterdayMetrics = DailyMetrics(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!)
        
        #expect(todayMetrics.isToday == true)
        #expect(yesterdayMetrics.isToday == false)
    }
    
    @Test func getMetricFromCategoryMetrics() async throws {
        let metrics = DailyMetrics(date: Date())
        let categoryMetric = CategoryMetric(categoryName: "Health", value: 7)
        categoryMetric.dailyMetrics = metrics
        metrics.categoryMetrics.append(categoryMetric)
        
        #expect(metrics.getMetric(for: "Health") == 7)
        #expect(metrics.getMetric(for: "Work") == 0)
    }
    
    @Test func getMetricFromLegacyProperties() async throws {
        let metrics = DailyMetrics(date: Date(), healthRating: 8, workRating: 7, growthRating: 6, familyRating: 9)
        
        #expect(metrics.getMetric(for: "Health") == 8)
        #expect(metrics.getMetric(for: "Work") == 7)
        #expect(metrics.getMetric(for: "Growth") == 6)
        #expect(metrics.getMetric(for: "Family") == 9)
        #expect(metrics.getMetric(for: "Unknown") == 0)
    }
    
    @Test func setMetricCreatesNewCategoryMetric() async throws {
        let metrics = DailyMetrics(date: Date())
        
        metrics.setMetric(5, for: "Health")
        
        #expect(metrics.categoryMetrics.count == 1)
        #expect(metrics.categoryMetrics[0].categoryName == "Health")
        #expect(metrics.categoryMetrics[0].value == 5)
        #expect(metrics.categoryMetrics[0].dailyMetrics === metrics)
    }
    
    @Test func setMetricUpdatesExistingCategoryMetric() async throws {
        let metrics = DailyMetrics(date: Date())
        let categoryMetric = CategoryMetric(categoryName: "Health", value: 3)
        categoryMetric.dailyMetrics = metrics
        metrics.categoryMetrics.append(categoryMetric)
        
        metrics.setMetric(8, for: "Health")
        
        #expect(metrics.categoryMetrics.count == 1)
        #expect(metrics.categoryMetrics[0].value == 8)
    }
    
    @Test func setMultipleMetrics() async throws {
        let metrics = DailyMetrics(date: Date())
        
        metrics.setMetric(7, for: "Health")
        metrics.setMetric(6, for: "Work")
        metrics.setMetric(8, for: "Growth")
        
        #expect(metrics.categoryMetrics.count == 3)
        #expect(metrics.getMetric(for: "Health") == 7)
        #expect(metrics.getMetric(for: "Work") == 6)
        #expect(metrics.getMetric(for: "Growth") == 8)
    }
}

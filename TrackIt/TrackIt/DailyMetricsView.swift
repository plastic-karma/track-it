import SwiftUI
import SwiftData

struct DailyMetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var metrics: [DailyMetrics]
    @Query(sort: \MetricCategory.sortOrder) private var categories: [MetricCategory]
    @StateObject private var notificationManager = NotificationManager.shared
    
    @State private var categoryMetrics = [String: Double]()
    @State private var notes = ""
    @State private var selectedDate = Date()
    @State private var isEditingMode = false
    
    private var activeCategories: [MetricCategory] {
        categories.filter(\ .isActive)
    }
    
    private var selectedDateMetrics: DailyMetrics? {
        metrics.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }
    
    private var isSelectedDateToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                    // Date Navigation Bar
                    HStack {
                        DateNavigationButton(
                            direction: .previous,
                            action: { navigateDate(by: -1) }
                        )
                        
                        Spacer()
                        
                        VStack {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if !isSelectedDateToday {
                                Button("Today") {
                                    selectedDate = Date()
                                    exitEditModeIfNeeded()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        DateNavigationButton(
                            direction: .next,
                            action: { navigateDate(by: 1) },
                            isDisabled: isSelectedDateToday
                        )
                    }
                    .padding()
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if let selectedMetrics = selectedDateMetrics {
                                if isEditingMode {
                                    VStack(spacing: 20) {
                                Text("✏️ Edit Metrics")
                                .font(.title)
                                .padding()
                            
                            VStack(spacing: 30) {
                                ForEach(activeCategories, id: \.name) { category in
                                    MetricSlider(
                                        title: category.displayTitle,
                                        value: Binding(
                                            get: { categoryMetrics[category.name] ?? 0.0 },
                                            set: { categoryMetrics[category.name] = $0 }
                                        )
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("📝 Notes")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TextField("How was your day? ✨", text: $notes, axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3, reservesSpace: true)
                                    .padding(.horizontal)
                            }
                            
                            HStack {
                                Button("❌ Cancel") {
                                    isEditingMode = false
                                    resetFormFields()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("✅ Save Changes") {
                                    updateMetrics(selectedMetrics)
                                    isEditingMode = false
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    } else {
                        VStack(spacing: 20) {
                            HStack {
                                Text(isSelectedDateToday ? "✨ Today's Metrics" : "📊 Metrics")
                                    .font(.title)
                                
                                Spacer()
                                
                                Button("✏️ Edit") {
                                    enterEditMode(for: selectedMetrics)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                ForEach(activeCategories, id: \.name) { category in
                                    MetricDisplay(
                                        title: category.displayTitle,
                                        value: selectedMetrics.getMetric(for: category.name)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            if !selectedMetrics.notes.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("📝 Notes")
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    Text(selectedMetrics.notes)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(8)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                } else {
                    VStack {
                        VStack {
                            Text(isSelectedDateToday ? "✨ Daily Metrics" : "📅 Add Metrics")
                                .font(.title)
                                .padding()
                        }
                        
                        VStack(spacing: 30) {
                            ForEach(activeCategories, id: \.name) { category in
                                MetricSlider(
                                    title: category.displayTitle,
                                    value: Binding(
                                        get: { categoryMetrics[category.name] ?? 0.0 },
                                        set: { categoryMetrics[category.name] = $0 }
                                    )
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("📝 Notes")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextField(isSelectedDateToday ? "How was your day? ✨" : "How was this day? ✨", text: $notes, axis: .vertical)
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3, reservesSpace: true)
                                .padding(.horizontal)
                        }
                        
                        Button("💾 Save Metrics") {
                            saveMetrics()
                        }
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }

                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside text fields
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Text("✨ TrackIt")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    NavigationLink(destination: StatisticsView()) {
                        Image(systemName: "chart.bar")
                    }
                    
                    NavigationLink(destination: SettingsView()) {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .onAppear {
                initializeNotifications()
                ensureDefaultCategories()
            }
        }
    }
}

// MARK: - Private Methods
private extension DailyMetricsView {
    func saveMetrics() {
        let newMetrics = DailyMetrics(date: selectedDate, notes: notes)
        modelContext.insert(newMetrics)
        
        // Set values for each category
        for category in activeCategories {
            let value = Int(categoryMetrics[category.name] ?? 0.0)
            newMetrics.setMetric(value, for: category.name)
        }
        
        do {
            try modelContext.save()
            resetFormFields()
        } catch {
            print("Failed to save metrics: \(error)")
        }
    }
    
    func enterEditMode(for metrics: DailyMetrics) {
        categoryMetrics.removeAll()
        for category in activeCategories {
            categoryMetrics[category.name] = Double(metrics.getMetric(for: category.name))
        }
        notes = metrics.notes
        isEditingMode = true
    }
    
    func updateMetrics(_ metrics: DailyMetrics) {
        // Update values for each category
        for category in activeCategories {
            let value = Int(categoryMetrics[category.name] ?? 0.0)
            metrics.setMetric(value, for: category.name)
        }
        metrics.notes = notes
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update metrics: \(error)")
        }
    }
    
    func resetFormFields() {
        categoryMetrics.removeAll()
        notes = ""
    }
    
    func exitEditModeIfNeeded() {
        guard isEditingMode else { return }
        isEditingMode = false
        resetFormFields()
    }
    
    func initializeNotifications() {
        let settings = AppSettings.getOrCreate(context: modelContext)
        guard settings.notificationsEnabled else { return }
        notificationManager.scheduleDailyNotification(
            at: settings.notificationTime,
            enabled: settings.notificationsEnabled
        )
    }
    
    func navigateDate(by days: Int) {
        selectedDate = Calendar.current.date(byAdding: .day, value: days, to: selectedDate) ?? selectedDate
        exitEditModeIfNeeded()
    }
    
    func ensureDefaultCategories() {
        guard categories.isEmpty else { return }
        MetricCategory.insertDefaultCategories(into: modelContext)
    }
}

// MARK: - Metric Helpers
extension Int {
    var metricColor: Color {
        switch self {
        case -2: return .red
        case -1: return .orange
        case 0: return .gray
        case 1: return .blue
        case 2: return .green
        default: return .gray
        }
    }
    
    var metricEmoji: String {
        switch self {
        case -2: return "😞"
        case -1: return "😕"
        case 0: return "😐"
        case 1: return "🙂"
        case 2: return "😊"
        default: return "😐"
        }
    }
}

struct MetricDisplay: View {
    let title: String
    let value: Int
    
    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
            Spacer()
            HStack(spacing: 8) {
                Text(value.metricEmoji)
                    .font(.title2)
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(value.metricColor)
                    .frame(width: 40, height: 40)
                    .background(value.metricColor.opacity(0.2))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal)
    }
}

struct MetricSlider: View {
    let title: String
    @Binding var value: Double
    
    private var intValue: Int { Int(value) }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                HStack(spacing: 4) {
                    Text(intValue.metricEmoji)
                        .font(.title3)
                    Text("\(intValue)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(intValue.metricColor)
                }
            }
            
            Slider(value: $value, in: -2...2, step: 1) {
                Text(title)
            } minimumValueLabel: {
                Text("-2")
                    .font(.caption)
            } maximumValueLabel: {
                Text("+2")
                    .font(.caption)
            }
            .tint(intValue.metricColor)
        }
    }
}

// MARK: - Date Navigation Component
struct DateNavigationButton: View {
    enum Direction {
        case previous
        case next
        
        var iconName: String {
            switch self {
            case .previous: return "chevron.left"
            case .next: return "chevron.right"
            }
        }
    }
    
    let direction: Direction
    let action: () -> Void
    let isDisabled: Bool
    
    init(direction: Direction, action: @escaping () -> Void, isDisabled: Bool = false) {
        self.direction = direction
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Image(systemName: direction.iconName)
                .font(.title2)
                .foregroundColor(.blue)
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.3 : 1.0)
    }
}

#Preview {
    DailyMetricsView()
        .modelContainer(for: [DailyMetrics.self, MetricCategory.self, CategoryMetric.self], inMemory: true)
}

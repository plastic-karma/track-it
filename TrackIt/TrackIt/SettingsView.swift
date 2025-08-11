import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var notificationManager = NotificationManager.shared
    @Query(sort: \MetricCategory.sortOrder) private var categories: [MetricCategory]
    @State private var settings: AppSettings?
    @State private var showingPermissionAlert = false
    @State private var showingAddCategory = false
    @State private var editingCategory: MetricCategory?
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Notifications")) {
                    HStack {
                        Label("Daily Reminders", systemImage: "bell")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings?.notificationsEnabled ?? false },
                            set: { newValue in
                                handleNotificationToggle(newValue)
                            }
                        ))
                    }
                    
                    if settings?.notificationsEnabled == true {
                        HStack {
                            Label("Reminder Time", systemImage: "clock")
                            Spacer()
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { settings?.notificationTime ?? Date() },
                                    set: { newTime in
                                        settings?.notificationTime = newTime
                                        saveSettings()
                                        updateNotificationSchedule()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                    
                    HStack {
                        Label("Weekly Stats Review", systemImage: "chart.bar.xaxis")
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { settings?.weeklyStatsReminderEnabled ?? false },
                            set: { newValue in
                                handleWeeklyStatsToggle(newValue)
                            }
                        ))
                    }
                    
                    if settings?.weeklyStatsReminderEnabled == true {
                        HStack {
                            Label("Review Day", systemImage: "calendar")
                            Spacer()
                            Picker("Day", selection: Binding(
                                get: { settings?.weeklyStatsReminderDay ?? 1 },
                                set: { newDay in
                                    settings?.weeklyStatsReminderDay = newDay
                                    saveSettings()
                                    updateWeeklyStatsSchedule()
                                }
                            )) {
                                Text("Sunday").tag(1)
                                Text("Monday").tag(2)
                                Text("Tuesday").tag(3)
                                Text("Wednesday").tag(4)
                                Text("Thursday").tag(5)
                                Text("Friday").tag(6)
                                Text("Saturday").tag(7)
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                        
                        HStack {
                            Label("Review Time", systemImage: "clock")
                            Spacer()
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { settings?.weeklyStatsReminderTime ?? Date() },
                                    set: { newTime in
                                        settings?.weeklyStatsReminderTime = newTime
                                        saveSettings()
                                        updateWeeklyStatsSchedule()
                                    }
                                ),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                }
                
                Section(header: Text("Metric Categories")) {
                    ForEach(categories.filter(\.isActive)) { category in
                        HStack {
                            Text(category.displayTitle)
                                .font(.body)
                            Spacer()
                            Button("Edit") {
                                editingCategory = category
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .onDelete(perform: deleteCategories)
                    .onMove(perform: moveCategories)
                    
                    Button {
                        showingAddCategory = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.green)
                            Text("Add Category")
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Label("App Version", systemImage: "info.circle")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                loadSettings()
                ensureDefaultCategories()
                updateWeeklyStatsSchedule()
            }
            .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
                Button("Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                }
                Button("Cancel", role: .cancel) {
                    settings?.notificationsEnabled = false
                    saveSettings()
                }
            } message: {
                Text("Please allow notifications in Settings to receive daily reminders.")
            }
            .sheet(isPresented: $showingAddCategory) {
                CategoryEditView(category: nil, onSave: { name, emoji in
                    addCategory(name: name, emoji: emoji)
                })
            }
            .sheet(item: $editingCategory) { category in
                CategoryEditView(category: category, onSave: { name, emoji in
                    updateCategory(category, name: name, emoji: emoji)
                })
            }
        }
    }
    
    private func loadSettings() {
        settings = AppSettings.getOrCreate(context: modelContext)
    }
    
    private func saveSettings() {
        do {
            try modelContext.save()
        } catch {
            print("Failed to save settings: \(error)")
        }
    }
    
    private func handleNotificationToggle(_ enabled: Bool) {
        if enabled && !notificationManager.hasPermission {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    if granted {
                        settings?.notificationsEnabled = true
                        saveSettings()
                        updateNotificationSchedule()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            settings?.notificationsEnabled = enabled
            saveSettings()
            updateNotificationSchedule()
        }
    }
    
    private func updateNotificationSchedule() {
        guard let settings = settings else { return }
        notificationManager.scheduleDailyNotification(
            at: settings.notificationTime,
            enabled: settings.notificationsEnabled
        )
    }
    
    private func handleWeeklyStatsToggle(_ enabled: Bool) {
        if enabled && !notificationManager.hasPermission {
            Task {
                let granted = await notificationManager.requestAuthorization()
                await MainActor.run {
                    if granted {
                        settings?.weeklyStatsReminderEnabled = true
                        saveSettings()
                        updateWeeklyStatsSchedule()
                    } else {
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            settings?.weeklyStatsReminderEnabled = enabled
            saveSettings()
            updateWeeklyStatsSchedule()
        }
    }
    
    private func updateWeeklyStatsSchedule() {
        guard let settings = settings else { return }
        notificationManager.scheduleWeeklyStatsReminder(
            day: settings.weeklyStatsReminderDay,
            time: settings.weeklyStatsReminderTime,
            enabled: settings.weeklyStatsReminderEnabled
        )
    }
    
    private func ensureDefaultCategories() {
        guard categories.isEmpty else { return }
        MetricCategory.insertDefaultCategories(into: modelContext)
    }
    
    private func addCategory(name: String, emoji: String) {
        let maxOrder = categories.map(\.sortOrder).max() ?? -1
        let newCategory = MetricCategory(
            name: name,
            emoji: emoji,
            sortOrder: maxOrder + 1
        )
        modelContext.insert(newCategory)
        saveSettings()
    }
    
    private func updateCategory(_ category: MetricCategory, name: String, emoji: String) {
        category.name = name
        category.emoji = emoji
        saveSettings()
    }
    
    private func deleteCategories(at offsets: IndexSet) {
        for index in offsets {
            let category = categories.filter(\.isActive)[index]
            category.isActive = false
        }
        saveSettings()
    }
    
    private func moveCategories(from source: IndexSet, to destination: Int) {
        var activeCategories = categories.filter(\.isActive)
        activeCategories.move(fromOffsets: source, toOffset: destination)
        
        for (index, category) in activeCategories.enumerated() {
            category.sortOrder = index
        }
        saveSettings()
    }
}

#Preview {
    SettingsView()
        .modelContainer(
            for: [AppSettings.self, DailyMetrics.self, MetricCategory.self, CategoryMetric.self],
            inMemory: true
        )
}

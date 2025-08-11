import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SettingsViewModelFactory.createEmpty()
    
    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("Notifications")) {
                    HStack {
                        Label("Daily Reminders", systemImage: "bell")
                        Spacer()
                        Toggle("", isOn: viewModel.notificationEnabledBinding())
                    }
                    
                    if viewModel.isNotificationEnabled {
                        HStack {
                            Label("Reminder Time", systemImage: "clock")
                            Spacer()
                            DatePicker(
                                "",
                                selection: viewModel.notificationTimeBinding(),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                    
                    HStack {
                        Label("Weekly Stats Review", systemImage: "chart.bar.xaxis")
                        Spacer()
                        Toggle("", isOn: viewModel.weeklyStatsEnabledBinding())
                    }
                    
                    if viewModel.isWeeklyStatsEnabled {
                        HStack {
                            Label("Review Day", systemImage: "calendar")
                            Spacer()
                            Picker("Day", selection: viewModel.weeklyStatsDayBinding()) {
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
                                selection: viewModel.weeklyStatsTimeBinding(),
                                displayedComponents: .hourAndMinute
                            )
                            .labelsHidden()
                        }
                    }
                }
                
                Section(header: Text("Metric Categories")) {
                    ForEach(viewModel.activeCategories) { category in
                        HStack {
                            Text(category.displayTitle)
                                .font(.body)
                            Spacer()
                            Button("Edit") {
                                viewModel.startEditingCategory(category)
                            }
                            .font(.caption)
                            .foregroundColor(.blue)
                        }
                    }
                    .onDelete { offsets in
                        do {
                            try viewModel.deleteCategories(at: offsets)
                        } catch {
                            print("Failed to delete categories: \(error)")
                        }
                    }
                    .onMove { source, destination in
                        do {
                            try viewModel.moveCategories(from: source, to: destination)
                        } catch {
                            print("Failed to move categories: \(error)")
                        }
                    }
                    
                    Button {
                        viewModel.startAddingCategory()
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
                viewModel.updateModelContext(modelContext)
                viewModel.ensureDefaultCategories()
                viewModel.updateWeeklyStatsSchedule()
            }
            .alert("Notification Permission Required", isPresented: $viewModel.showingPermissionAlert) {
                Button("Settings") {
                    viewModel.openSystemSettings()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.dismissPermissionAlert()
                }
            } message: {
                Text("Please allow notifications in Settings to receive daily reminders.")
            }
            .sheet(isPresented: $viewModel.showingAddCategory) {
                CategoryEditView(category: nil, onSave: { name, emoji in
                    do {
                        try viewModel.addCategory(name: name, emoji: emoji)
                    } catch {
                        print("Failed to add category: \(error)")
                    }
                })
            }
            .sheet(item: $viewModel.editingCategory) { category in
                CategoryEditView(category: category, onSave: { name, emoji in
                    do {
                        try viewModel.updateCategory(category, name: name, emoji: emoji)
                    } catch {
                        print("Failed to update category: \(error)")
                    }
                })
            }
        }
    }
}

#Preview {
    SettingsView()
        .modelContainer(
            for: [AppSettings.self, DailyMetrics.self, MetricCategory.self, CategoryMetric.self],
            inMemory: true
        )
}

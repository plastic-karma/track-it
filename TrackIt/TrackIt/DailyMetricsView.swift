import SwiftUI
import SwiftData

struct DailyMetricsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = DailyMetricsViewModelFactory.createEmpty()
    
    
    private var selectedDateMetrics: DailyMetrics? {
        viewModel.getMetricsForDate(viewModel.selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                    // Date Navigation Bar
                    HStack {
                        DateNavigationButton(
                            direction: .previous,
                            action: { viewModel.navigateDate(by: -1) }
                        )
                        
                        Spacer()
                        
                        VStack {
                            Text(viewModel.dateFormatter.string(from: viewModel.selectedDate))
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            if !viewModel.isSelectedDateToday {
                                Button("Today") {
                                    viewModel.navigateToToday()
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        
                        Spacer()
                        
                        DateNavigationButton(
                            direction: .next,
                            action: { viewModel.navigateDate(by: 1) },
                            isDisabled: viewModel.isSelectedDateToday
                        )
                    }
                    .padding()
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            if let selectedMetrics = selectedDateMetrics {
                                if viewModel.isEditingMode {
                                    VStack(spacing: 20) {
                                Text("✏️ Edit Metrics")
                                .font(.title)
                                .padding()
                            
                            VStack(spacing: 30) {
                                ForEach(viewModel.activeCategories, id: \.name) { category in
                                    MetricStepper(
                                        title: category.displayTitle,
                                        value: viewModel.categoryMetricBinding(for: category.name)
                                    )
                                }
                            }
                            .padding(.horizontal)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text("📝 Notes")
                                    .font(.headline)
                                    .padding(.horizontal)
                                
                                TextField("How was your day? ✨", text: viewModel.notesBinding(), axis: .vertical)
                                    .textFieldStyle(.roundedBorder)
                                    .lineLimit(3, reservesSpace: true)
                                    .padding(.horizontal)
                            }
                            
                            HStack {
                                Button("❌ Cancel") {
                                    viewModel.cancelEditMode()
                                }
                                .buttonStyle(.bordered)
                                
                                Button("✅ Save Changes") {
                                    do {
                                        try viewModel.updateMetrics(selectedMetrics)
                                        viewModel.isEditingMode = false
                                    } catch {
                                        print("Failed to update metrics: \(error)")
                                    }
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                        }
                    } else {
                        VStack(spacing: 20) {
                            HStack {
                                Text(viewModel.isSelectedDateToday ? "✨ Today's Metrics" : "📊 Metrics")
                                    .font(.title)
                                
                                Spacer()
                                
                                Button("✏️ Edit") {
                                    viewModel.enterEditMode(for: selectedMetrics)
                                }
                                .buttonStyle(.bordered)
                            }
                            .padding(.horizontal)
                            
                            VStack(spacing: 15) {
                                ForEach(viewModel.activeCategories, id: \.name) { category in
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
                            Text(viewModel.isSelectedDateToday ? "✨ Daily Metrics" : "📅 Add Metrics")
                                .font(.title)
                                .padding()
                        }
                        
                        VStack(spacing: 30) {
                            ForEach(viewModel.activeCategories, id: \.name) { category in
                                MetricStepper(
                                    title: category.displayTitle,
                                    value: viewModel.categoryMetricBinding(for: category.name)
                                )
                            }
                        }
                        .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            Text("📝 Notes")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            TextField(
                                viewModel.isSelectedDateToday ? "How was your day? ✨" : "How was this day? ✨",
                                text: viewModel.notesBinding(),
                                axis: .vertical
                            )
                                .textFieldStyle(.roundedBorder)
                                .lineLimit(3, reservesSpace: true)
                                .padding(.horizontal)
                        }
                        
                        HStack {
                            Button {
                                viewModel.resetFormFields()
                            } label: {
                                Image(systemName: "arrow.counterclockwise.circle")
                                    .font(.title2)
                            }
                            .buttonStyle(.bordered)
                            
                            Button {
                                do {
                                    try viewModel.saveMetrics()
                                } catch {
                                    print("Failed to save metrics: \(error)")
                                }
                            } label: {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding()
                    }
                }

                    }
                    .onTapGesture {
                        // Dismiss keyboard when tapping outside text fields
                        UIApplication.shared.sendAction(
                            #selector(UIResponder.resignFirstResponder),
                            to: nil,
                            from: nil,
                            for: nil
                        )
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
                viewModel.updateModelContext(modelContext)
                viewModel.initializeNotifications()
                viewModel.ensureDefaultCategories()
            }
        }
    }
}

#Preview {
    DailyMetricsView()
        .modelContainer(for: [DailyMetrics.self, MetricCategory.self, CategoryMetric.self], inMemory: true)
}

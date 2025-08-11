import SwiftUI

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

struct MetricStepper: View {
    let title: String
    @Binding var value: Double
    
    private var intValue: Int { Int(value) }
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(intValue.metricEmoji)
                    .font(.title2)
            }
            
            HStack {
                Button {
                    if value > -2 {
                        value -= 1
                    }
                } label: {
                    Image(systemName: "minus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value > -2 ? .blue : .gray)
                }
                .disabled(value <= -2)
                
                Spacer()
                
                HStack(spacing: 8) {
                    ForEach(-2...2, id: \.self) { rating in
                        Button {
                            value = Double(rating)
                        } label: {
                            Circle()
                                .fill(rating == intValue ? rating.metricColor : Color.gray.opacity(0.3))
                                .frame(width: 12, height: 12)
                        }
                    }
                }
                
                Spacer()
                
                Button {
                    if value < 2 {
                        value += 1
                    }
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(value < 2 ? .blue : .gray)
                }
                .disabled(value >= 2)
            }
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

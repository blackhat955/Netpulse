import SwiftUI

private enum SpeedTier {
    case unusable, poor, fair, good, excellent
    
    static func from(_ mbps: Double) -> SpeedTier {
        if mbps >= 50 { return .excellent }
        if mbps >= 15 { return .good }
        if mbps >= 8 { return .fair }
        if mbps >= 3 { return .poor }
        return .unusable
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .teal
        case .fair: return .orange
        case .poor: return .pink
        case .unusable: return .red
        }
    }
    
    var label: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .unusable: return "Unusable"
        }
    }
}

struct SpeedMeter: View {
    let mbps: Double
    let peak: Double
    let progress: Double
    
    private var tier: SpeedTier { .from(mbps) }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: 18)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(progress, 0), 1)))
                .stroke(style: StrokeStyle(lineWidth: 18, lineCap: .round))
                .fill(AngularGradient(gradient: Gradient(colors: [tier.color.opacity(0.2), tier.color]), center: .center))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.15), value: progress)
            VStack(spacing: 6) {
                Text(String(format: "%.1f", mbps))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                Text("Mbps")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                Text(tier.label)
                    .font(.caption)
                    .foregroundColor(tier.color)
            }
        }
        .frame(width: 220, height: 220)
        .shadow(color: tier.color.opacity(0.25), radius: 8, x: 0, y: 8)
    }
}

import SwiftUI

struct AnimatedCircleHero: View {
    let isRunning: Bool
    let label: String
    let icon: String
    let valueText: String
    let accent: Color
    let progress: Double
    
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let pulse = isRunning ? 1.0 + 0.03 * sin(t * 6) : 1.0
            let speed = isRunning ? 90.0 : 0.0
            let rotation = t * speed
            let trim = isRunning ? 0.2 + 0.7 * max(0, min(1, progress)) : 0.0
            let colors = [accent, accent.opacity(0.6), accent]
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.15), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: trim)
                    .stroke(AngularGradient(colors: colors, center: .center), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: accent.opacity(0.25), radius: 8, x: 0, y: 8)
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(accent)
                    Text(valueText)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Text(label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .frame(width: 180, height: 180)
            .scaleEffect(pulse)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 24).fill(Color(.secondarySystemBackground)))
        }
    }
}

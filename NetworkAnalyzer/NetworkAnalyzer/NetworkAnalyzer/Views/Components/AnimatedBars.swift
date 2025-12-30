import SwiftUI

struct AnimatedBars: View {
    let active: Bool
    let color: Color
    var barCount: Int = 24
    var speed: Double = 2.0
    var maxHeight: CGFloat = 80
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                let count = max(10, barCount)
                let spacing: CGFloat = 5
                let available = geo.size.width - spacing * CGFloat(count - 1) - 20
                let barWidth = max(5, available / CGFloat(count))
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                        .overlay(
                            LinearGradient(colors: [color.opacity(0.12), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    
                    HStack(spacing: spacing) {
                        ForEach(0..<count, id: \.self) { i in
                            let phase = Double(i) * 0.32
                            let base = 0.45 + 0.55 * max(0, sin(t * speed + phase))
                            let noise = 0.12 * sin(t * (speed * 1.7) + Double(i))
                            let level = active ? (base + noise) : 0.22
                            let height = max(10, CGFloat(level) * maxHeight)
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            color.opacity(0.95),
                                            color.opacity(0.55)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: barWidth, height: height)
                                .shadow(color: color.opacity(0.25), radius: 3, x: 0, y: 3)
                        }
                    }
                    .padding(.horizontal, 10)
                    
                    Rectangle()
                        .fill(
                            LinearGradient(colors: [.white.opacity(0.0), .white.opacity(0.25), .white.opacity(0.0)], startPoint: .leading, endPoint: .trailing)
                        )
                        .blendMode(.screen)
                        .offset(x: CGFloat(sin(t * (speed * 0.6))) * geo.size.width * 0.35)
                }
            }
        }
        .frame(height: maxHeight + 24)
    }
}

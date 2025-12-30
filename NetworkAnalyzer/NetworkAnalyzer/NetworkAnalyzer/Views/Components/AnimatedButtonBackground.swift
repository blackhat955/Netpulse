import SwiftUI

struct AnimatedButtonBackground: View {
    let active: Bool
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let offset = CGFloat(sin(t * 0.8)) * 0.5 + 0.5
            ZStack {
                LinearGradient(colors: [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing)
                    .hueRotation(.degrees(active ? 20 * sin(t * 1.2) : 0))
                    .opacity(0.95)
                LinearGradient(colors: [.white.opacity(0.2), .clear], startPoint: .topLeading, endPoint: .bottomTrailing)
                    .opacity(active ? 0.3 : 0.15)
                    .offset(x: offset * 8, y: -offset * 6)
            }
        }
    }
}

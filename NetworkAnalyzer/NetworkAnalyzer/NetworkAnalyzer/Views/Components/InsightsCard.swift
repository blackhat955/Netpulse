import SwiftUI

struct InsightsCard: View {
    let sustainedMbps: Double
    let stability: Double
    let avg: Double
    let peak: Double
    
    private var headline: String {
        if sustainedMbps < 10 { return "Low sustained speed" }
        if stability > 0.35 { return "High variability" }
        if avg > 0 && (avg - sustainedMbps) / max(avg, 1) > 0.4 { return "Burst vs sustained gap" }
        return "Network looks stable"
    }
    
    private var detail: String {
        if sustainedMbps < 10 { return "Downloads and streaming may stutter. Reduce concurrent traffic or test closer to router." }
        if stability > 0.35 { return "Speed fluctuates a lot. Possible Wi‑Fi interference or congestion. Try moving closer or switching channel." }
        if avg > 0 && (avg - sustainedMbps) / max(avg, 1) > 0.4 { return "Short bursts are fast but sustained rate drops. Bufferbloat or routing congestion likely." }
        return "Good balance of throughput and stability for everyday use."
    }
    
    var body: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(headline).font(.headline)
                    Spacer()
                }
                Text(detail).foregroundColor(.secondary).font(.caption)
                HStack(spacing: 8) {
                    Capsule().fill(Color.blue.opacity(0.12)).overlay(Text("Avg \(String(format: "%.1f", avg)) Mbps").font(.caption)).frame(height: 26)
                    Capsule().fill(Color.purple.opacity(0.12)).overlay(Text("Sustained \(String(format: "%.1f", sustainedMbps)) Mbps").font(.caption)).frame(height: 26)
                    Capsule().fill(Color.orange.opacity(0.12)).overlay(Text("Stability \(String(format: "%.0f%%", stability * 100))").font(.caption)).frame(height: 26)
                }
            }
        }
    }
}

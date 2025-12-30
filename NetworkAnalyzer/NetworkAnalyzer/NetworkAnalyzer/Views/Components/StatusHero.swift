import SwiftUI

struct StatusHero: View {
    let latencyMs: Double
    let jitterMs: Double
    let lossPercent: Double
    let dnsMs: Double
    let online: Bool
    
    private var reliability: Double {
        let pingScore = max(0, 1 - min(latencyMs, 200) / 200)
        let jitterScore = max(0, 1 - min(jitterMs, 100) / 100)
        let lossScore = max(0, 1 - min(lossPercent, 5) / 5)
        let dnsScore = max(0, 1 - min(dnsMs, 200) / 200)
        return (pingScore + jitterScore + lossScore + dnsScore) / 4
    }
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                AnimatedGradient()
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                
                Circle()
                    .trim(from: 0, to: reliability)
                    .stroke(
                        AngularGradient(colors: online ? [.blue, .teal, .blue] : [.red, .orange, .red], center: .center),
                        style: StrokeStyle(lineWidth: 10, lineCap: .round)
                    )
                    .frame(width: 160, height: 160)
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (online ? Color.blue : Color.red).opacity(0.25), radius: 6, x: 0, y: 6)
                    .animation(.easeInOut(duration: 0.4), value: reliability)
                
                MoodOrb(metrics: MoodMetrics(
                    latencyMs: latencyMs,
                    jitterMs: jitterMs,
                    lossPercent: lossPercent,
                    dnsMs: dnsMs
                ))
                .frame(width: 130, height: 130)
            }
            
            HStack(spacing: 8) {
                Capsule()
                    .fill(Color(.systemBackground).opacity(0.9))
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "speedometer").foregroundColor(.blue)
                            Text(String(format: "%.0f ms", latencyMs))
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                    )
                    .frame(height: 22)
                Capsule()
                    .fill(Color(.systemBackground).opacity(0.9))
                    .overlay(
                        HStack(spacing: 6) {
                            Image(systemName: "antenna.radiowaves.left.and.right").foregroundColor(.orange)
                            Text(String(format: "%.1f%% loss", lossPercent))
                                .font(.caption2)
                                .foregroundColor(.primary)
                        }
                        .padding(.horizontal, 10)
                    )
                    .frame(height: 22)
            }
        }
    }
}

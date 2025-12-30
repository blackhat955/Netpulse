import SwiftUI

struct ScenarioBadges: View {
    let sustained: Double
    let stability: Double
    
    private var hdPass: Bool { sustained >= 25 && stability <= 0.3 }
    private var uhdPass: Bool { sustained >= 50 && stability <= 0.3 }
    private var gamingPass: Bool { sustained >= 10 && stability <= 0.15 }
    private var callPass: Bool { sustained >= 5 && stability <= 0.3 }
    
    var body: some View {
        HStack(spacing: 12) {
            scenario(title: "HD Streaming", pass: hdPass, color: .blue)
            scenario(title: "Gaming", pass: gamingPass, color: .purple)
            scenario(title: "Video Call", pass: callPass, color: .teal)
        }
    }
    
    private func scenario(title: String, pass: Bool, color: Color) -> some View {
        GlassCard {
            HStack {
                Text(title).font(.subheadline)
                Spacer()
                Capsule()
                    .fill((pass ? Color.green : Color.red).opacity(0.12))
                    .overlay(Text(pass ? "Pass" : "Fail").font(.caption))
                    .frame(height: 24)
            }
        }
    }
}

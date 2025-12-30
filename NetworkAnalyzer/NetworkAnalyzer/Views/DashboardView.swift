import SwiftUI
import Charts
import UIKit

struct DashboardView: View {
    @StateObject private var vm = NetworkStatusVM()
    @StateObject private var history = HistoryVM()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                StatusHero(
                    latencyMs: history.latencyTrend.last?.value ?? 0,
                    jitterMs: history.jitterTrend.last?.value ?? 0,
                    lossPercent: history.lossTrend.last?.value ?? 0,
                    dnsMs: history.dnsTrend.last?.value ?? 0,
                    online: vm.status.status == .online
                )
                .padding(.top, 4)
                HStack {
                    Circle()
                        .fill(vm.status.status == .online ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(vm.status.status == .online ? "Online" : "Offline")
                        .font(.headline)
                    Spacer()
                }
                HStack {
                    Badge(text: vm.status.interface.rawValue.capitalized, color: .blue)
                    Badge(text: vm.status.isConstrained ? "Constrained" : "Unconstrained", color: vm.status.isConstrained ? .orange : .green)
                    Badge(text: vm.status.isExpensive ? "Expensive" : "Normal", color: vm.status.isExpensive ? .red : .green)
                    Spacer()
                }
                HStack(spacing: 12) {
                    StatCard(title: "Latency", value: String(format: "%.0f ms", history.latencyTrend.last?.value ?? 0), color: .blue, icon: "speedometer")
                    StatCard(title: "Jitter", value: String(format: "%.0f ms", history.jitterTrend.last?.value ?? 0), color: .purple, icon: "waveform.path.ecg")
                }
                HStack(spacing: 12) {
                    StatCard(title: "DNS", value: String(format: "%.0f ms", history.dnsTrend.last?.value ?? 0), color: .teal, icon: "globe")
                    StatCard(title: "Loss", value: String(format: "%.1f%%", history.lossTrend.last?.value ?? 0), color: .orange, icon: "exclamationmark.triangle")
                }
                VStack(alignment: .leading) {
                    Text("Latency Trend")
                        .font(.headline)
                    Chart(history.latencyTrend) {
                        LineMark(
                            x: .value("Time", $0.date),
                            y: .value("Latency", $0.value)
                        )
                    }
                    .frame(height: 140)
                }
                HStack {
                    NavigationLink(destination: RunTestView()) {
                        Text("Run Test")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    NavigationLink(destination: SpeedTestView()) {
                        Text("Speed Test")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                Spacer()
            }
            .padding()
            .navigationTitle("NetPulse")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    DashboardView()
}

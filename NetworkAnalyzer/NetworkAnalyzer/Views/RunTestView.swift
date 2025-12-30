import SwiftUI
import Charts

struct RunTestView: View {
    @StateObject private var vm = TestRunnerVM()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                ZStack {
                    AnimatedGradient()
                        .frame(height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    MoodOrb(metrics: MoodMetrics(
                        latencyMs: vm.lastResult?.httpTotalMs ?? 0,
                        jitterMs: vm.lastResult?.jitterMs ?? 0,
                        lossPercent: vm.lastResult?.lossPercent ?? 0,
                        dnsMs: vm.lastResult?.dnsMs ?? 0
                    ))
                    .frame(width: 140, height: 140)
                }
                
                Button {
                    Task { await vm.runTest() }
                } label: {
                    HStack {
                        Image(systemName: vm.isRunning ? "stop.circle" : "play.circle")
                        Text(vm.isRunning ? "Running..." : "Run Test")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        AnimatedButtonBackground(active: vm.isRunning)
                            .clipShape(Capsule())
                    )
                }
                .foregroundColor(.white)
                .scaleEffect(vm.isRunning ? 1.02 : 1.0)
                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: vm.isRunning)
                .disabled(vm.isRunning)
                
                if !vm.progressText.isEmpty {
                    Text(vm.progressText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let r = vm.lastResult {
                    HStack(spacing: 12) {
                        StatCard(title: "Latency", value: String(format: "%.0f ms", r.httpTotalMs ?? 0), color: .blue, icon: "speedometer")
                        StatCard(title: "Jitter", value: String(format: "%.0f ms", r.jitterMs ?? 0), color: .purple, icon: "waveform.path.ecg")
                    }
                    HStack(spacing: 12) {
                        StatCard(title: "Loss", value: String(format: "%.1f%%", r.lossPercent ?? 0), color: .orange, icon: "antenna.radiowaves.left.and.right")
                        StatCard(title: "DNS", value: String(format: "%.0f ms", r.dnsMs ?? 0), color: .teal, icon: "globe")
                    }
                    
                    GlassCard {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Quality: \(r.qualityLabel.rawValue.capitalized) (\(r.score))")
                                .font(.headline)
                            Text("Latency Samples")
                                .font(.subheadline)
                            Chart {
                                if let total = r.httpTotalMs {
                                    PointMark(x: .value("P50", "P50"), y: .value("ms", r.latencyP50 ?? total))
                                    PointMark(x: .value("P95", "P95"), y: .value("ms", r.latencyP95 ?? total))
                                }
                            }
                            .frame(height: 120)
                        }
                    }
                } else {
                    GlassCard {
                        HStack {
                            Image(systemName: "bolt.fill").foregroundColor(.purple)
                            Text("Run a test to see latency, jitter, loss and DNS")
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Run Test")
    }
}

#Preview {
    RunTestView()
}

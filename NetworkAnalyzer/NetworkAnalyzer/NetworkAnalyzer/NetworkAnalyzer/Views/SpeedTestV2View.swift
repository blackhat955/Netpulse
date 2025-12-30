import SwiftUI
import Charts

struct SpeedTestV2View: View {
    @State private var isRunning = false
    @State private var downloadResult: SpeedTestResult?
    @State private var uploadResult: SpeedTestResult?
    @State private var samples: [SpeedSample] = []
    @State private var progress: Double = 0
    @State private var duration: TimeInterval = 8
    @State private var startAt: Date?
    private let service = SpeedTestService()
    
    private var downloadAvg: Double { downloadResult?.averageMbps ?? 0 }
    private var uploadAvg: Double { uploadResult?.averageMbps ?? 0 }
    private var latencyMs: Double {
        guard let s = samples.last else { return 0 }
        return max(0, 1000.0 / max(0.001, s.mbps))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                GlassCard {
                    VStack(spacing: 16) {
                        AnimatedCircleHero(
                            isRunning: isRunning,
                            label: isRunning ? "Testing..." : "Ready",
                            icon: "bolt.fill",
                            valueText: String(format: "%.1f Mbps", isRunning ? max(downloadAvg, uploadAvg) : 0),
                            accent: (downloadAvg >= uploadAvg ? Color.blue : Color.purple),
                            progress: progress
                        )
                        Button {
                            Task { await startStop() }
                        } label: {
                            Text(isRunning ? "Stop Test" : "Start Test")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                GlassCard {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill").foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Download").font(.headline)
                            Text(String(format: "%.1f Mbps", downloadAvg)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    GradientProgressBar(progress: min(downloadAvg/200.0, 1.0), colors: [.blue, .cyan])
                }
                
                GlassCard {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill").foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Upload").font(.headline)
                            Text(String(format: "%.1f Mbps", uploadAvg)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    GradientProgressBar(progress: min(uploadAvg/200.0, 1.0), colors: [.purple, .pink])
                }
                
                GlassCard {
                    HStack {
                        Image(systemName: "timer").foregroundColor(.teal)
                        VStack(alignment: .leading) {
                            Text("Latency").font(.headline)
                            Text(String(format: "%.0f ms", latencyMs)).foregroundColor(.secondary)
                        }
                        Spacer()
                    }
                    GradientProgressBar(progress: min(1.0 - min(latencyMs/200.0, 1.0), 1.0), colors: [.teal, .blue])
                }
                
                HStack {
                    Button {
                        Task { await startStop() }
                    } label: {
                        HStack {
                            Image(systemName: "speedometer")
                            Text(isRunning ? "Testing..." : "Start Speed Test")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRunning)
                    
                    VStack(spacing: 8) {
                        Text("Duration")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Button { duration = min(20, duration + 1) } label: {
                            Image(systemName: "plus")
                                .frame(width: 36, height: 36)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                        }
                        Text(String(format: "%.0f s", duration)).font(.caption).foregroundColor(.secondary)
                        Button { duration = max(5, duration - 1) } label: {
                            Image(systemName: "minus")
                                .frame(width: 36, height: 36)
                                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.secondarySystemBackground)))
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Network Test")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func startStop() async {
        if isRunning {
            isRunning = false
            return
        }
        await start()
    }
    
    private func start() async {
        if isRunning { return }
        isRunning = true
        samples = []
        downloadResult = nil
        uploadResult = nil
        progress = 0
        startAt = Date()
        let downloadURL = URL(string: "https://speed.hetzner.de/100MB.bin")!
        let uploadURL = URL(string: "https://httpbin.org/post")!
        do {
            Task {
                while isRunning {
                    if let start = startAt {
                        let elapsed = Date().timeIntervalSince(start)
                        progress = min(1, max(0, elapsed / duration))
                    }
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
            }
            let d = try await service.runDownload(url: downloadURL, durationSec: duration)
            downloadResult = d
            samples = d.samples
            if !isRunning { return }
            progress = 0
            startAt = Date()
            let u = try await service.runUpload(url: uploadURL, durationSec: duration, payloadMB: 8)
            uploadResult = u
        } catch {
            downloadResult = SpeedTestResult(averageMbps: 0, peakMbps: 0, samples: [], durationSec: 0)
            uploadResult = SpeedTestResult(averageMbps: 0, peakMbps: 0, samples: [], durationSec: 0)
        }
        isRunning = false
        progress = 1
    }
}

#Preview {
    SpeedTestV2View()
}

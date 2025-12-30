import SwiftUI
import Charts

struct SpeedTestView: View {
    @State private var isRunning = false
    @State private var downloadResult: SpeedTestResult?
    @State private var uploadResult: SpeedTestResult?
    @State private var samples: [SpeedSample] = []
    @State private var progress: Double = 0
    @State private var duration: TimeInterval = 8
    @State private var startAt: Date?
    @State private var mode: Mode = .download
    enum Mode { case download, upload }
    private let service = SpeedTestService()
    
    private var currentAvg: Double {
        switch mode {
        case .download: return downloadResult?.averageMbps ?? 0
        case .upload: return uploadResult?.averageMbps ?? 0
        }
    }
    
    private var currentPeak: Double {
        switch mode {
        case .download: return downloadResult?.peakMbps ?? 0
        case .upload: return uploadResult?.peakMbps ?? 0
        }
    }
    
    private var currentSamples: [SpeedSample] {
        switch mode {
        case .download: return downloadResult?.samples ?? []
        case .upload: return uploadResult?.samples ?? []
        }
    }
    
    private var sustainedMbps: Double {
        let vals = currentSamples.map { $0.mbps }.sorted()
        guard !vals.isEmpty else { return 0 }
        return vals[vals.count / 2]
    }
    
    private var stabilityScore: Double {
        let vals = currentSamples.map { $0.mbps }
        guard vals.count > 1 else { return 0 }
        let mean = vals.reduce(0, +) / Double(vals.count)
        let varSum = vals.reduce(0) { $0 + pow($1 - mean, 2) }
        let std = sqrt(varSum / Double(vals.count))
        return mean > 0 ? std / mean : 0
    }
    
    private var estimated100MBTimeSec: Double {
        let mbps = max(0.1, sustainedMbps)
        let megabits = 100.0 * 8.0
        return megabits / mbps
    }
    
    private var smoothedSamples: [SpeedSample] {
        let vals = currentSamples
        guard !vals.isEmpty else { return [] }
        let window = 5
        var out: [SpeedSample] = []
        for i in 0..<vals.count {
            let start = max(0, i - window + 1)
            let slice = vals[start...i].map { $0.mbps }
            let avg = slice.reduce(0, +) / Double(slice.count)
            out.append(SpeedSample(timestamp: vals[i].timestamp, mbps: avg))
        }
        return out
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack {
                    AnimatedGradient()
                        .frame(height: 260)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                    SpeedMeter(
                        mbps: currentAvg,
                        peak: currentPeak,
                        progress: progress
                    )
                }
                
                Picker("", selection: $mode) {
                    Text("Download").tag(Mode.download)
                    Text("Upload").tag(Mode.upload)
                }
                .pickerStyle(.segmented)
                
                HStack(spacing: 12) {
                    Badge(text: String(format: "Avg %.1f Mbps", currentAvg), color: .blue)
                    Badge(text: String(format: "Peak %.1f Mbps", currentPeak), color: .purple)
                    Badge(text: String(format: "%.0fs", duration), color: .gray)
                    Spacer()
                }
                
                
                AnimatedBars(active: isRunning, color: mode == .download ? .blue : .purple)
                
                if !currentSamples.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Stability & Trend")
                            .font(.headline)
                        Chart {
                            ForEach(currentSamples) {
                                LineMark(
                                    x: .value("Time", $0.timestamp),
                                    y: .value("Mbps", $0.mbps)
                                )
                                .foregroundStyle(.blue)
                            }
                            ForEach(smoothedSamples) {
                                LineMark(
                                    x: .value("Time", $0.timestamp),
                                    y: .value("Sustained", $0.mbps)
                                )
                                .foregroundStyle(.purple)
                            }
                        }
                        .frame(height: 180)
                        .chartXAxis {
                            AxisMarks(preset: .aligned, position: .bottom)
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading)
                        }
                    }
                }
                    HStack(spacing: 12) {
                        StatCard(title: "Sustained", value: String(format: "%.1f Mbps", sustainedMbps), color: .purple, icon: "line.3.horizontal.decrease.circle")
                        StatCard(title: "Stability", value: String(format: "%.0f%%", stabilityScore * 100), color: .orange, icon: "waveform.path")
                    }
                    HStack(spacing: 12) {
                        StatCard(title: "100MB time", value: String(format: "%.1f s", estimated100MBTimeSec), color: .blue, icon: "clock")
                        StatCard(title: mode == .download ? "Profile" : "Profile", value: profileText, color: .teal, icon: "person")
                    }
                
                HStack {
                    Button {
                        Task { await start() }
                    } label: {
                        HStack {
                            Image(systemName: "speedometer")
                            Text(isRunning ? "Testing..." : "Start Speed Test")
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            AnimatedButtonBackground(active: isRunning)
                                .clipShape(Capsule())
                        )
                    }
                    .foregroundColor(.white)
                    .scaleEffect(isRunning ? 1.02 : 1.0)
                    .animation(.spring(response: 0.35, dampingFraction: 0.8), value: isRunning)
                    .disabled(isRunning)
                    
                    DurationStepper(value: $duration, range: 5...20, step: 1)
                }
                .padding(.horizontal, 2)
                
                HStack(spacing: 12) {
                    StatCard(
                        title: "Download",
                        value: String(format: "Avg %.1f / Peak %.1f", downloadResult?.averageMbps ?? 0, downloadResult?.peakMbps ?? 0),
                        color: .blue,
                        icon: "arrow.down.circle"
                    )
                    StatCard(
                        title: "Upload",
                        value: String(format: "Avg %.1f / Peak %.1f", uploadResult?.averageMbps ?? 0, uploadResult?.peakMbps ?? 0),
                        color: .purple,
                        icon: "arrow.up.circle"
                    )
                }
            }
            .padding()
        }
        .navigationTitle("Speed Test")
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
            if mode == .download { samples = d.samples }
            progress = 0
            startAt = Date()
            let u = try await service.runUpload(url: uploadURL, durationSec: duration, payloadMB: 8)
            uploadResult = u
            if mode == .upload { samples = u.samples }
        } catch {
            downloadResult = SpeedTestResult(averageMbps: 0, peakMbps: 0, samples: [], durationSec: 0)
            uploadResult = SpeedTestResult(averageMbps: 0, peakMbps: 0, samples: [], durationSec: 0)
        }
        isRunning = false
        progress = 1
    }
    
    private var profileText: String {
        if sustainedMbps >= 50 { return "4K streaming ready" }
        if sustainedMbps >= 25 { return "HD streaming ready" }
        if sustainedMbps >= 10 { return "Smooth browsing" }
        return "Basic browsing only"
    }
}

#Preview {
    SpeedTestView()
}

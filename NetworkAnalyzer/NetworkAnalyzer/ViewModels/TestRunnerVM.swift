import Foundation
import SwiftUI
import Network
import Combine

@MainActor
final class TestRunnerVM: ObservableObject {
    @Published var isRunning = false
    @Published var progressText = ""
    @Published var lastResult: TestRunRecord?
    
    private let pathService: PathMonitorServiceProtocol
    private let testService: NetworkTestServiceProtocol
    private let storage: StorageServiceProtocol
    private let metrics: MetricsAggregatorProtocol
    private let baseline: BaselineAnomalyServiceProtocol
    
    init(
        pathService: PathMonitorServiceProtocol = PathMonitorService(),
        testService: NetworkTestServiceProtocol = NetworkTestService(),
        storage: StorageServiceProtocol = StorageService(),
        metrics: MetricsAggregatorProtocol = MetricsAggregator(),
        baseline: BaselineAnomalyServiceProtocol = BaselineAnomalyService()
    ) {
        self.pathService = pathService
        self.testService = testService
        self.storage = storage
        self.metrics = metrics
        self.baseline = baseline
        pathService.start()
    }
    
    func runTest(
        host: String = "apple.com",
        httpURL: URL = URL(string: "https://www.apple.com")!,
        probes: Int = 10,
        timeout: TimeInterval = 5
    ) async {
        if isRunning { return }
        isRunning = true
        defer { isRunning = false }
        
        let status = pathService.currentStatus
        
        progressText = "Resolving DNS"
        let dnsMs = try? await testService.dnsResolutionTime(host: host)
        
        progressText = "TCP connect"
        let tcpMs = try? await testService.tcpConnectTime(host: host, port: 443)
        
        progressText = "HTTP latency"
        let http = try? await testService.httpLatency(url: httpURL, timeout: timeout)
        
        progressText = "Packet loss probes"
        let loss = await testService.packetLossEstimate(url: httpURL, probes: probes, timeout: timeout)
        
        let jitter = metrics.jitter(from: loss.latenciesMs)
        let p50 = metrics.percentile(0.50, samples: loss.latenciesMs)
        let p95 = metrics.percentile(0.95, samples: loss.latenciesMs)
        let (score, label) = metrics.score(latencyMs: http?.totalMs, jitterMs: jitter, lossPercent: loss.lossPercent, dnsMs: dnsMs)
        let anomaly = baseline.evaluate(latencyMs: http?.totalMs ?? 0, lossPercent: loss.lossPercent, dnsMs: dnsMs ?? 0)
        
        let record = TestRunRecord(
            id: UUID(),
            timestamp: Date(),
            interfaceType: status.interface,
            isExpensive: status.isExpensive,
            isConstrained: status.isConstrained,
            dnsMs: dnsMs,
            tcpMs: tcpMs,
            httpTtfbMs: http?.ttfbMs,
            httpTotalMs: http?.totalMs,
            latencyP50: p50,
            latencyP95: p95,
            latencySamplesCount: loss.latenciesMs.count,
            jitterMs: jitter,
            lossPercent: loss.lossPercent,
            qualityLabel: label,
            score: score,
            anomalyFlag: anomaly.flag,
            anomalyReason: anomaly.reason
        )
        
        do {
            try storage.saveRun(record)
            lastResult = record
            progressText = "Saved"
        } catch {
            progressText = "Save failed"
        }
    }
}

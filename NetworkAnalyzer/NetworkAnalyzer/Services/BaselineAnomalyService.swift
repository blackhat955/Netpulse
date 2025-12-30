import Foundation

struct AnomalyResult {
    let flag: Bool
    let reason: String?
}

protocol BaselineAnomalyServiceProtocol {
    func buildBaseline() -> (p95Latency: Double, avgDns: Double, lossThreshold: Double)
    func evaluate(latencyMs: Double, lossPercent: Double, dnsMs: Double) -> AnomalyResult
}

final class BaselineAnomalyService: BaselineAnomalyServiceProtocol {
    private let storage: StorageServiceProtocol
    
    init(storage: StorageServiceProtocol = StorageService()) {
        self.storage = storage
    }
    
    func buildBaseline() -> (p95Latency: Double, avgDns: Double, lossThreshold: Double) {
        let runs = (try? storage.fetchRuns(limit: 50)) ?? []
        let latencies = runs.map { $0.httpTotalMs }
        let p95 = percentile(0.95, latencies)
        let avgDns = avg(runs.map { $0.dnsMs })
        let lossThresh = max(2.0, avg(runs.map { $0.lossPercent }) * 2.0)
        return (p95, avgDns, lossThresh)
    }
    
    func evaluate(latencyMs: Double, lossPercent: Double, dnsMs: Double) -> AnomalyResult {
        let base = buildBaseline()
        var reasons: [String] = []
        if latencyMs >= base.p95Latency * 2.0 {
            reasons.append("Latency above 2× baseline p95")
        }
        if lossPercent >= base.lossThreshold {
            reasons.append("Packet loss above threshold")
        }
        if dnsMs >= base.avgDns * 1.8 {
            reasons.append("DNS unusually slow")
        }
        let flag = !reasons.isEmpty
        return AnomalyResult(flag: flag, reason: flag ? reasons.joined(separator: "; ") : nil)
    }
    
    private func percentile(_ p: Double, _ samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let s = samples.sorted()
        let idx = Int(Double(s.count - 1) * p)
        return s[max(0, min(s.count - 1, idx))]
    }
    
    private func avg(_ samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 0 }
        return samples.reduce(0, +) / Double(samples.count)
    }
}

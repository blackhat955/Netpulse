import Foundation

protocol MetricsAggregatorProtocol {
    func jitter(from samples: [Double]) -> Double
    func percentile(_ p: Double, samples: [Double]) -> Double
    func score(latencyMs: Double?, jitterMs: Double?, lossPercent: Double?, dnsMs: Double?) -> (score: Int, label: QualityLabel)
}

final class MetricsAggregator: MetricsAggregatorProtocol {
    func jitter(from samples: [Double]) -> Double {
        guard samples.count > 1 else { return 0 }
        var sum: Double = 0
        for i in 1..<samples.count {
            sum += abs(samples[i] - samples[i-1])
        }
        return sum / Double(samples.count - 1)
    }
    
    func percentile(_ p: Double, samples: [Double]) -> Double {
        guard !samples.isEmpty else { return 0 }
        let sorted = samples.sorted()
        let idx = Int(Double(sorted.count - 1) * p)
        return sorted[max(0, min(sorted.count - 1, idx))]
    }
    
    func score(latencyMs: Double?, jitterMs: Double?, lossPercent: Double?, dnsMs: Double?) -> (score: Int, label: QualityLabel) {
        let latency = latencyMs ?? 0
        let jitter = jitterMs ?? 0
        let loss = lossPercent ?? 0
        let dns = dnsMs ?? 0
        var s = 100
        s -= min(60, Int(latency / 3))          // latency weight
        s -= min(25, Int(jitter / 2))           // jitter weight
        s -= min(10, Int(loss * 2))             // loss weight
        s -= min(5, Int(dns / 50))              // dns weight
        s = max(0, s)
        let label: QualityLabel
        if s >= 85 { label = .excellent }
        else if s >= 70 { label = .good }
        else if s >= 55 { label = .fair }
        else if s >= 35 { label = .poor }
        else { label = .unusable }
        return (s, label)
    }
}

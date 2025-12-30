import Foundation

enum QualityLabel: String {
    case excellent
    case good
    case fair
    case poor
    case unusable
}

struct TestRunRecord {
    let id: UUID
    let timestamp: Date
    let interfaceType: InterfaceType
    let isExpensive: Bool
    let isConstrained: Bool
    let dnsMs: Double?
    let tcpMs: Double?
    let httpTtfbMs: Double?
    let httpTotalMs: Double?
    let latencyP50: Double?
    let latencyP95: Double?
    let latencySamplesCount: Int
    let jitterMs: Double?
    let lossPercent: Double?
    let qualityLabel: QualityLabel
    let score: Int
    let anomalyFlag: Bool
    let anomalyReason: String?
}

import Foundation
import Network

struct HTTPResult {
    let ttfbMs: Double?
    let totalMs: Double
}

protocol NetworkTestServiceProtocol {
    func dnsResolutionTime(host: String) async throws -> Double
    func tcpConnectTime(host: String, port: NWEndpoint.Port) async throws -> Double
    func httpLatency(url: URL, timeout: TimeInterval) async throws -> HTTPResult
    func packetLossEstimate(url: URL, probes: Int, timeout: TimeInterval) async -> (lossPercent: Double, latenciesMs: [Double])
}

final class NetworkTestService: NSObject, NetworkTestServiceProtocol, URLSessionTaskDelegate {
    private var lastMetrics: URLSessionTaskMetrics?
    private lazy var session: URLSession = {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 15
        cfg.timeoutIntervalForResource = 20
        cfg.waitsForConnectivity = true
        return URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
    }()
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didFinishCollecting metrics: URLSessionTaskMetrics) {
        lastMetrics = metrics
    }
    
    func dnsResolutionTime(host: String) async throws -> Double {
        try Task.checkCancellation()
        let start = DispatchTime.now()
        let cfHost = CFHostCreateWithName(nil, host as CFString).takeRetainedValue()
        var resolved: DarwinBoolean = false
        CFHostStartInfoResolution(cfHost, .addresses, nil)
        if let _ = CFHostGetAddressing(cfHost, &resolved), resolved.boolValue {
            let end = DispatchTime.now()
            return Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
        } else {
            throw NSError(domain: "NetPulse.DNS", code: -1, userInfo: [NSLocalizedDescriptionKey: "DNS resolution failed"])
        }
    }
    
    func tcpConnectTime(host: String, port: NWEndpoint.Port) async throws -> Double {
        try Task.checkCancellation()
        let params = NWParameters.tcp
        let connection = NWConnection(host: NWEndpoint.Host(host), port: port, using: params)
        let start = DispatchTime.now()
        return try await withCheckedThrowingContinuation { cont in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    let end = DispatchTime.now()
                    connection.cancel()
                    let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
                    cont.resume(returning: ms)
                case .failed(let error):
                    connection.cancel()
                    cont.resume(throwing: error)
                default:
                    break
                }
            }
            connection.start(queue: .global(qos: .userInitiated))
        }
    }
    
    func httpLatency(url: URL, timeout: TimeInterval) async throws -> HTTPResult {
        try Task.checkCancellation()
        let req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
        let start = DispatchTime.now()
        _ = try await session.data(for: req)
        let end = DispatchTime.now()
        let totalMs = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
        var ttfbMs: Double?
        if let metrics = lastMetrics,
           let transaction = metrics.transactionMetrics.first {
            if let fetchStart = transaction.fetchStartDate,
               let firstByte = transaction.responseStartDate {
                ttfbMs = firstByte.timeIntervalSince(fetchStart) * 1000.0
            }
        }
        return HTTPResult(ttfbMs: ttfbMs, totalMs: totalMs)
    }
    
    func packetLossEstimate(url: URL, probes: Int, timeout: TimeInterval) async -> (lossPercent: Double, latenciesMs: [Double]) {
        var failures = 0
        var latencies: [Double] = []
        for i in 0..<probes {
            if Task.isCancelled { break }
            var req = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: timeout)
            req.httpMethod = "HEAD"
            let start = DispatchTime.now()
            do {
                let (_, resp) = try await session.data(for: req)
                _ = resp
                let end = DispatchTime.now()
                let ms = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000.0
                latencies.append(ms)
            } catch {
                failures += 1
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        let lossPercent = probes == 0 ? 0.0 : (Double(failures) / Double(probes)) * 100.0
        return (lossPercent, latencies)
    }
}

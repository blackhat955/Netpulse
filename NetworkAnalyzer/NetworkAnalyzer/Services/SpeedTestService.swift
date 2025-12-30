import Foundation

struct SpeedSample: Identifiable {
    let id = UUID()
    let timestamp: Date
    let mbps: Double
}

struct SpeedTestResult {
    let averageMbps: Double
    let peakMbps: Double
    let samples: [SpeedSample]
    let durationSec: Double
}

protocol SpeedTestServiceProtocol {
    func runDownload(url: URL, durationSec: TimeInterval) async throws -> SpeedTestResult
    func runUpload(url: URL, durationSec: TimeInterval, payloadMB: Int) async throws -> SpeedTestResult
}

final class SpeedTestService: NSObject, SpeedTestServiceProtocol, URLSessionDataDelegate, URLSessionTaskDelegate {
    private var bytesReceived: Int64 = 0
    private var bytesSent: Int64 = 0
    private var startTime: Date = Date()
    private var samples: [SpeedSample] = []
    
    func runDownload(url: URL, durationSec: TimeInterval) async throws -> SpeedTestResult {
        bytesReceived = 0
        samples = []
        startTime = Date()
        
        let cfg = URLSessionConfiguration.ephemeral
        cfg.allowsCellularAccess = true
        cfg.timeoutIntervalForResource = durationSec + 5
        let session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
        
        let task = session.dataTask(with: URLRequest(url: url))
        task.resume()
        
        try await Task.sleep(nanoseconds: UInt64(durationSec * 1_000_000_000))
        task.cancel()
        
        let elapsed = Date().timeIntervalSince(startTime)
        let averageMbps = elapsed > 0 ? (Double(bytesReceived) * 8.0) / elapsed / 1_000_000.0 : 0
        let peakMbps = samples.map { $0.mbps }.max() ?? averageMbps
        return SpeedTestResult(averageMbps: averageMbps, peakMbps: peakMbps, samples: samples, durationSec: elapsed)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived += Int64(data.count)
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 0 {
            let mbps = (Double(bytesReceived) * 8.0) / elapsed / 1_000_000.0
            samples.append(SpeedSample(timestamp: Date(), mbps: mbps))
        }
    }
    
    func runUpload(url: URL, durationSec: TimeInterval, payloadMB: Int) async throws -> SpeedTestResult {
        bytesSent = 0
        samples = []
        startTime = Date()
        
        let cfg = URLSessionConfiguration.ephemeral
        cfg.allowsCellularAccess = true
        cfg.timeoutIntervalForResource = durationSec + 5
        let session = URLSession(configuration: cfg, delegate: self, delegateQueue: nil)
        
        let size = max(1, payloadMB) * 1_000_000
        let payload = Data(count: size)
        var keepRunning = true
        
        let urlRequest = URLRequest(url: url)
        let task = session.uploadTask(with: urlRequest, from: payload)
        task.resume()
        
        try await Task.sleep(nanoseconds: UInt64(durationSec * 1_000_000_000))
        keepRunning = false
        task.cancel()
        
        let elapsed = Date().timeIntervalSince(startTime)
        let averageMbps = elapsed > 0 ? (Double(bytesSent) * 8.0) / elapsed / 1_000_000.0 : 0
        let peakMbps = samples.map { $0.mbps }.max() ?? averageMbps
        return SpeedTestResult(averageMbps: averageMbps, peakMbps: peakMbps, samples: samples, durationSec: elapsed)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent sent: Int64, totalBytesExpectedToSend: Int64) {
        self.bytesSent = sent
        let elapsed = Date().timeIntervalSince(startTime)
        if elapsed > 0 {
            let mbps = (Double(self.bytesSent) * 8.0) / elapsed / 1_000_000.0
            samples.append(SpeedSample(timestamp: Date(), mbps: mbps))
        }
    }
}

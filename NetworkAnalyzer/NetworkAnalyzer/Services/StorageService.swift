import Foundation
import CoreData

protocol StorageServiceProtocol {
    func saveRun(_ record: TestRunRecord) throws
    func fetchRuns(limit: Int) throws -> [RunResult]
    func fetchRuns(days: Int) throws -> [RunResult]
    func rebuildDailySummaries() throws
    func fetchDailySummaries(limit: Int) throws -> [DailySummary]
    func exportCSV() throws -> Data
    func exportJSON() throws -> Data
}

final class StorageService: StorageServiceProtocol {
    private let container: NSPersistentContainer
    private var context: NSManagedObjectContext { container.viewContext }
    
    init(container: NSPersistentContainer = PersistenceController.shared.container) {
        self.container = container
    }
    
    func saveRun(_ record: TestRunRecord) throws {
        let obj = RunResult(context: context)
        obj.id = record.id
        obj.timestamp = record.timestamp
        obj.interfaceType = record.interfaceType.rawValue
        obj.isExpensive = record.isExpensive
        obj.isConstrained = record.isConstrained
        obj.dnsMs = record.dnsMs ?? 0
        obj.tcpMs = record.tcpMs ?? 0
        obj.httpTtfbMs = record.httpTtfbMs ?? 0
        obj.httpTotalMs = record.httpTotalMs ?? 0
        obj.jitterMs = record.jitterMs ?? 0
        obj.lossPercent = record.lossPercent ?? 0
        obj.qualityLabel = record.qualityLabel.rawValue
        obj.score = Int32(record.score)
        obj.anomalyFlag = record.anomalyFlag
        obj.anomalyReason = record.anomalyReason
        obj.latencyP50 = record.latencyP50 ?? 0
        obj.latencyP95 = record.latencyP95 ?? 0
        obj.latencySamplesCount = Int32(record.latencySamplesCount)
        try context.save()
    }
    
    func fetchRuns(limit: Int) throws -> [RunResult] {
        let req = RunResult.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        req.fetchLimit = limit
        return try context.fetch(req) as! [RunResult]
    }
    
    func fetchRuns(days: Int) throws -> [RunResult] {
        let calendar = Calendar.current
        guard let from = calendar.date(byAdding: .day, value: -days, to: Date()) else { return [] }
        let req = RunResult.fetchRequest()
        req.predicate = NSPredicate(format: "timestamp >= %@", from as NSDate)
        req.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
        return try context.fetch(req) as! [RunResult]
    }
    
    func rebuildDailySummaries() throws {
        let fetch = RunResult.fetchRequest()
        let runs = try context.fetch(fetch) as! [RunResult]
        let grouped = Dictionary(grouping: runs) { (run) -> Date in
            let comps = Calendar.current.dateComponents([.year, .month, .day], from: run.timestamp ?? Date())
            return Calendar.current.date(from: comps) ?? Date()
        }
        for (day, items) in grouped {
            let summary = DailySummary(context: context)
            summary.date = day
            summary.runsCount = Int32(items.count)
            summary.avgLatencyMs = items.map { $0.httpTotalMs }.reduce(0, +) / Double(max(items.count, 1))
            summary.avgJitterMs = items.map { $0.jitterMs }.reduce(0, +) / Double(max(items.count, 1))
            summary.avgDnsMs = items.map { $0.dnsMs }.reduce(0, +) / Double(max(items.count, 1))
            summary.avgLossPercent = items.map { $0.lossPercent }.reduce(0, +) / Double(max(items.count, 1))
        }
        try context.save()
    }
    
    func fetchDailySummaries(limit: Int) throws -> [DailySummary] {
        let req = DailySummary.fetchRequest()
        req.sortDescriptors = [NSSortDescriptor(key: "date", ascending: false)]
        req.fetchLimit = limit
        return try context.fetch(req) as! [DailySummary]
    }
    
    func exportCSV() throws -> Data {
        let runs = try fetchRuns(limit: Int.max)
        var rows: [String] = []
        rows.append("id,timestamp,interface,isExpensive,isConstrained,dnsMs,tcpMs,ttfbMs,totalMs,jitterMs,lossPercent,quality,score,anomalyFlag,anomalyReason,latencyP50,latencyP95,latencySamplesCount")
        for r in runs {
            let s = [
                r.id?.uuidString ?? "",
                ISO8601DateFormatter().string(from: r.timestamp ?? Date()),
                r.interfaceType ?? "",
                String(r.isExpensive),
                String(r.isConstrained),
                String(r.dnsMs),
                String(r.tcpMs),
                String(r.httpTtfbMs),
                String(r.httpTotalMs),
                String(r.jitterMs),
                String(r.lossPercent),
                r.qualityLabel ?? "",
                String(r.score),
                String(r.anomalyFlag),
                r.anomalyReason ?? "",
                String(r.latencyP50),
                String(r.latencyP95),
                String(r.latencySamplesCount)
            ].joined(separator: ",")
            rows.append(s)
        }
        return (rows.joined(separator: "\n")).data(using: .utf8) ?? Data()
    }
    
    struct JSONRun: Codable {
        let id: String
        let timestamp: String
        let interface: String
        let isExpensive: Bool
        let isConstrained: Bool
        let dnsMs: Double
        let tcpMs: Double
        let ttfbMs: Double
        let totalMs: Double
        let jitterMs: Double
        let lossPercent: Double
        let quality: String
        let score: Int32
        let anomalyFlag: Bool
        let anomalyReason: String?
        let latencyP50: Double
        let latencyP95: Double
        let latencySamplesCount: Int32
    }
    
    func exportJSON() throws -> Data {
        let runs = try fetchRuns(limit: Int.max)
        let mapped = runs.map { r in
            JSONRun(
                id: r.id?.uuidString ?? "",
                timestamp: ISO8601DateFormatter().string(from: r.timestamp ?? Date()),
                interface: r.interfaceType ?? "",
                isExpensive: r.isExpensive,
                isConstrained: r.isConstrained,
                dnsMs: r.dnsMs,
                tcpMs: r.tcpMs,
                ttfbMs: r.httpTtfbMs,
                totalMs: r.httpTotalMs,
                jitterMs: r.jitterMs,
                lossPercent: r.lossPercent,
                quality: r.qualityLabel ?? "",
                score: r.score,
                anomalyFlag: r.anomalyFlag,
                anomalyReason: r.anomalyReason,
                latencyP50: r.latencyP50,
                latencyP95: r.latencyP95,
                latencySamplesCount: r.latencySamplesCount
            )
        }
        return try JSONEncoder().encode(mapped)
    }
}

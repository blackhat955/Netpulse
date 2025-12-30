import Foundation
import SwiftUI
import Combine

struct MetricPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

@MainActor
final class HistoryVM: ObservableObject {
    @Published var latencyTrend: [MetricPoint] = []
    @Published var dnsTrend: [MetricPoint] = []
    @Published var lossTrend: [MetricPoint] = []
    @Published var jitterTrend: [MetricPoint] = []
    
    private let storage: StorageServiceProtocol
    
    init(storage: StorageServiceProtocol = StorageService()) {
        self.storage = storage
        Task {
            try? await load()
        }
    }
    
    func load(limit: Int = 20) async throws {
        let runs = try storage.fetchRuns(limit: limit)
        latencyTrend = runs.compactMap { r in
            guard let ts = r.timestamp else { return nil }
            return MetricPoint(date: ts, value: r.httpTotalMs)
        }.reversed()
        dnsTrend = runs.compactMap { r in
            guard let ts = r.timestamp else { return nil }
            return MetricPoint(date: ts, value: r.dnsMs)
        }.reversed()
        lossTrend = runs.compactMap { r in
            guard let ts = r.timestamp else { return nil }
            return MetricPoint(date: ts, value: r.lossPercent)
        }.reversed()
        jitterTrend = runs.compactMap { r in
            guard let ts = r.timestamp else { return nil }
            return MetricPoint(date: ts, value: r.jitterMs)
        }.reversed()
    }
}

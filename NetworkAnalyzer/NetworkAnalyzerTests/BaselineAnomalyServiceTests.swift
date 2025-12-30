import XCTest
@testable import NetworkAnalyzer

final class BaselineAnomalyServiceTests: XCTestCase {
    final class MockStorage: StorageServiceProtocol {
        var runs: [RunResult] = []
        func saveRun(_ record: TestRunRecord) throws {}
        func fetchRuns(limit: Int) throws -> [RunResult] { runs }
        func fetchRuns(days: Int) throws -> [RunResult] { runs }
        func rebuildDailySummaries() throws {}
        func fetchDailySummaries(limit: Int) throws -> [DailySummary] { [] }
        func exportCSV() throws -> Data { Data() }
        func exportJSON() throws -> Data { Data() }
    }
    
    func makeRun(latency: Double, dns: Double, loss: Double) -> RunResult {
        let r = RunResult(context: PersistenceController.shared.container.viewContext)
        r.httpTotalMs = latency
        r.dnsMs = dns
        r.lossPercent = loss
        r.timestamp = Date()
        return r
    }
    
    func testEvaluateFlagsWhenAboveBaseline() {
        let storage = MockStorage()
        storage.runs = [
            makeRun(latency: 50, dns: 20, loss: 0),
            makeRun(latency: 60, dns: 22, loss: 0.5),
            makeRun(latency: 55, dns: 18, loss: 0.2)
        ]
        let svc = BaselineAnomalyService(storage: storage)
        let res1 = svc.evaluate(latencyMs: 200, lossPercent: 3.0, dnsMs: 50)
        XCTAssertTrue(res1.flag)
        XCTAssertNotNil(res1.reason)
        let res2 = svc.evaluate(latencyMs: 40, lossPercent: 0.1, dnsMs: 15)
        XCTAssertFalse(res2.flag)
    }
}

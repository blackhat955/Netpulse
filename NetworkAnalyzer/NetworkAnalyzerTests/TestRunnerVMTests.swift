import XCTest
@testable import NetworkAnalyzer
import Network

final class TestRunnerVMTests: XCTestCase {
    final class MockPath: PathMonitorServiceProtocol {
        var currentStatus: NetworkStatus = NetworkStatus(status: .online, interface: .wifi, isConstrained: false, isExpensive: false)
        func updates() -> AsyncStream<NetworkStatus> { AsyncStream { _ in } }
        func start() {}
        func stop() {}
    }
    final class MockTests: NetworkTestServiceProtocol {
        func dnsResolutionTime(host: String) async throws -> Double { 12 }
        func tcpConnectTime(host: String, port: NWEndpoint.Port) async throws -> Double { 34 }
        func httpLatency(url: URL, timeout: TimeInterval) async throws -> HTTPResult { HTTPResult(ttfbMs: 20, totalMs: 120) }
        func packetLossEstimate(url: URL, probes: Int, timeout: TimeInterval) async -> (lossPercent: Double, latenciesMs: [Double]) { (5.0, [100, 120, 110, 115]) }
    }
    final class MockStorage: StorageServiceProtocol {
        var saved: TestRunRecord?
        func saveRun(_ record: TestRunRecord) throws { saved = record }
        func fetchRuns(limit: Int) throws -> [RunResult] { [] }
        func fetchRuns(days: Int) throws -> [RunResult] { [] }
        func rebuildDailySummaries() throws {}
        func fetchDailySummaries(limit: Int) throws -> [DailySummary] { [] }
        func exportCSV() throws -> Data { Data() }
        func exportJSON() throws -> Data { Data() }
    }
    
    func testRunTestProducesRecordAndSaves() async {
        let vm = TestRunnerVM(
            pathService: MockPath(),
            testService: MockTests(),
            storage: MockStorage(),
            metrics: MetricsAggregator(),
            baseline: BaselineAnomalyService(storage: MockStorage())
        )
        await vm.runTest(host: "example.com", httpURL: URL(string: "https://example.com")!, probes: 4, timeout: 1)
        XCTAssertNotNil(vm.lastResult)
        XCTAssertEqual(vm.progressText, "Saved")
        XCTAssertEqual(vm.lastResult?.interfaceType, .wifi)
    }
}

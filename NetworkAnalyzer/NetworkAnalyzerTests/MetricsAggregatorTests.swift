import XCTest
@testable import NetworkAnalyzer

final class MetricsAggregatorTests: XCTestCase {
    func testJitterComputesAverageAbsoluteDelta() {
        let agg = MetricsAggregator()
        let j = agg.jitter(from: [10, 12, 9, 15])
        XCTAssertGreaterThan(j, 0)
        XCTAssertEqual(round(j), 3)
    }
    
    func testPercentileBoundsAndOrder() {
        let agg = MetricsAggregator()
        let p50 = agg.percentile(0.5, samples: [1, 2, 100, 4, 5])
        let p95 = agg.percentile(0.95, samples: [1, 2, 100, 4, 5])
        XCTAssertTrue(p50 <= p95)
        XCTAssertEqual(p50, 4)
        XCTAssertEqual(p95, 100)
    }
    
    func testScoreLabelMapping() {
        let agg = MetricsAggregator()
        let s1 = agg.score(latencyMs: 20, jitterMs: 2, lossPercent: 0, dnsMs: 20)
        XCTAssertEqual(s1.label, .excellent)
        let s2 = agg.score(latencyMs: 120, jitterMs: 30, lossPercent: 5, dnsMs: 200)
        XCTAssertEqual(s2.label, .poor)
    }
}

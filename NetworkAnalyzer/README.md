# NetPulse

Offline-first network quality analyzer for iOS. Focuses on latency, jitter, DNS time, and packet-loss estimate. Visualizes a “network mood” using Core Animation and Swift Charts. No backend; local storage only.

## What It Looks Like
- Live status at the top shows how healthy your connection is
- One tap runs a quick test and saves the result on your phone
- Clear cards show Latency, Jitter, DNS and Loss with friendly colors
- Trend charts help you see if things get better or worse over time

### Screenshots

![Dashboard hero](../Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.27.png)

![Metrics cards](../Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.37.png)

![Trend and actions](../Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.49.png)

![Run test flow](../Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.55.png)

## Tech Stack
Swift + SwiftUI, Network.framework, URLSession, Core Animation, Swift Charts, BackgroundTasks, Core Data, async/await.

## Architecture
- MVVM + Services
- UI: DashboardView, RunTestView, HistoryView, DetailView, SettingsView
- ViewModels: NetworkStatusVM, TestRunnerVM, HistoryVM, MoodVM
- Services: PathMonitorService, NetworkTestService, MetricsAggregator, StorageService, BaselineAnomalyService, BackgroundScheduler

## Tests Per Run
- DNS resolution time (CFHost)
- TCP connect time to host:443 (NWConnection)
- HTTP latency (TTFB via URLSessionTaskMetrics + total)
- Packet loss estimate: run N HTTP HEAD probes with timeouts; loss% = failures/N
- Jitter: mean absolute delta between latency samples
Loss is an estimate; no ICMP ping.

## Quality Scoring
Combines latency, jitter, loss, and DNS into a 0–100 score labeled: Excellent, Good, Fair, Poor, Unusable. Profiles weigh metrics differently in UI.

## Baseline & Anomalies
Baseline from last 50 runs: p95 latency, avg DNS, dynamic loss threshold. Flags anomalies when latency ≥ 2× p95, loss above threshold, or DNS unusually slow. Provides reason text.

## Storage
Core Data entities RunResult and DailySummary. Batching via Core Data saves. Export CSV/JSON available in StorageService.

## Background Tasks
Schedules periodic tests using BGTaskScheduler. Keep work small and respect system constraints.

## Privacy
No personal data, no tracking, no uploading. Data stays on device.

## How To Try
- Open the app and check the status ring at the top
- Tap “Run Test” to measure your connection in a few seconds
- See Latency, Jitter, DNS and Loss cards update with your results
- Look at “Latency Trend” to spot patterns across the day
- Everything is saved locally; export CSV/JSON if you want a copy

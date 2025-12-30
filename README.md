# NetPulse

Offline-first network quality analyzer for iOS. Measures latency, jitter, DNS time, and packet loss. Stores everything on device and visualizes status with a clean, modern UI.

## What It Looks Like
- Live status ring shows how healthy your connection is
- One tap runs a quick test and saves the result locally
- Clear cards for Latency, Jitter, DNS and Loss
- Trend chart helps you spot patterns across the day

### Screenshots

![Dashboard hero](./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.27.png)

![Metrics cards](./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.37.png)

![Trend and actions](./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.49.png)

![Run test flow](./Simulator%20Screenshot%20-%20iPhone%2017%20Pro%20-%202025-12-30%20at%2017.04.55.png)

## How To Try
- Open the app and check the status ring at the top
- Tap “Run Test” to measure your connection in a few seconds
- See cards update with your results and review the trend chart
- Export CSV/JSON via the storage service if you want a copy

## Tech
Swift + SwiftUI, Network.framework, URLSession, Swift Charts, Core Data, async/await.

import Foundation
import Network

protocol PathMonitorServiceProtocol {
    var currentStatus: NetworkStatus { get }
    func updates() -> AsyncStream<NetworkStatus>
    func start()
    func stop()
}

final class PathMonitorService: PathMonitorServiceProtocol {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "netpulse.path.monitor")
    private var continuation: AsyncStream<NetworkStatus>.Continuation?
    private var latest: NetworkStatus = NetworkStatus(status: .offline, interface: .none, isConstrained: false, isExpensive: false)
    
    var currentStatus: NetworkStatus { latest }
    
    func updates() -> AsyncStream<NetworkStatus> {
        AsyncStream { continuation in
            self.continuation = continuation
        }
    }
    
    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            let status: ConnectionStatus = path.status == .satisfied ? .online : .offline
            let iface = InterfaceType.from(path: path)
            let value = NetworkStatus(status: status, interface: iface, isConstrained: path.isConstrained, isExpensive: path.isExpensive)
            self.latest = value
            self.continuation?.yield(value)
        }
        monitor.start(queue: queue)
    }
    
    func stop() {
        monitor.cancel()
        continuation?.finish()
        continuation = nil
    }
}

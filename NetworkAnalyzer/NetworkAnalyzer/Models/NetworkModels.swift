import Foundation
import Network

enum ConnectionStatus {
    case online
    case offline
}

enum InterfaceType: String {
    case wifi
    case cellular
    case wired
    case loopback
    case other
    case none
}

struct NetworkStatus: Equatable {
    let status: ConnectionStatus
    let interface: InterfaceType
    let isConstrained: Bool
    let isExpensive: Bool
}
extension InterfaceType {
    static func from(path: NWPath) -> InterfaceType {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wired }
        if path.usesInterfaceType(.loopback) { return .loopback }
        if path.availableInterfaces.isEmpty { return .none }
        return .other
    }
}

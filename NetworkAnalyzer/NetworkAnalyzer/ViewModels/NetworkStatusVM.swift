import Foundation
import SwiftUI
import Combine

@MainActor
final class NetworkStatusVM: ObservableObject {
    @Published var status: NetworkStatus = NetworkStatus(status: .offline, interface: .none, isConstrained: false, isExpensive: false)
    
    private let service: PathMonitorServiceProtocol
    private var streamTask: Task<Void, Never>?
    
    init(service: PathMonitorServiceProtocol = PathMonitorService()) {
        self.service = service
        service.start()
        streamTask = Task {
            for await value in service.updates() {
                self.status = value
            }
        }
    }
    
    deinit {
        service.stop()
        streamTask?.cancel()
    }
}

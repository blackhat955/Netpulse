import Foundation
import BackgroundTasks

protocol BackgroundSchedulerProtocol {
    func register()
    func schedule()
    func handle(task: BGTask)
}

final class BackgroundScheduler: BackgroundSchedulerProtocol {
    static let taskIdentifier = "com.netpulse.networktest"
    
    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.taskIdentifier, using: nil) { task in
            self.handle(task: task)
        }
    }
    
    func schedule() {
        let req = BGAppRefreshTaskRequest(identifier: Self.taskIdentifier)
        req.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 30)
        try? BGTaskScheduler.shared.submit(req)
    }
    
    func handle(task: BGTask) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let op = BlockOperation {
            let vm = TestRunnerVM()
            Task { await vm.runTest() }
        }
        task.expirationHandler = {
            queue.cancelAllOperations()
        }
        queue.addOperation(op)
        task.setTaskCompleted(success: true)
    }
}

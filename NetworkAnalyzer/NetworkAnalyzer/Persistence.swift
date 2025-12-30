import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    @MainActor
    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        for _ in 0..<5 {
            let run = RunResult(context: viewContext)
            run.id = UUID()
            run.timestamp = Date()
            run.interfaceType = "wifi"
            run.isExpensive = false
            run.isConstrained = false
            run.dnsMs = 40
            run.tcpMs = 80
            run.httpTtfbMs = 120
            run.httpTotalMs = 200
            run.jitterMs = 8
            run.lossPercent = 0
            run.qualityLabel = "good"
            run.score = 80
            run.anomalyFlag = false
            run.anomalyReason = nil
            run.latencyP50 = 180
            run.latencyP95 = 240
            run.latencySamplesCount = 10
        }
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    
    let container: NSPersistentContainer
    
    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "NetworkAnalyzer")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores(completionHandler: { (_, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

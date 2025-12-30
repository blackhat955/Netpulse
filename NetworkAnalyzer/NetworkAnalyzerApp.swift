//
//  NetworkAnalyzerApp.swift
//  NetworkAnalyzer
//
//  Created by DURGESH TIWARI on 12/30/25.
//

import SwiftUI
import CoreData

@main
struct NetworkAnalyzerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

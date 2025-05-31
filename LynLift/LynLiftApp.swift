//
//  LynLiftApp.swift
//  LynLift
//
//  Created by Mushfiqur Rahman on 2025-05-31.
//

import SwiftUI

@main
struct LynLiftApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

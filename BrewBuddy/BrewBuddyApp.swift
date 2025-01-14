//
//  BrewBuddyApp.swift
//  BrewBuddy
//
//  Created by Noam Efergan on 14/01/2025.
//

import SwiftUI
import SwiftData

@main
struct BrewBuddyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
          CoffeeDataModel.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
          ContainerView()
        }
        .modelContainer(sharedModelContainer)
    }
}

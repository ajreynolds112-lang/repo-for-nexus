//
//  AudienceAmpApp.swift
//  AudienceAmp
//
//  Universal app entry point — iOS 17+ & macOS 14+ (Mac Catalyst)
//

import SwiftUI
import SwiftData

@main
struct AudienceAmpApp: App {

    // MARK: - SwiftData Container
    let modelContainer: ModelContainer = {
        let schema = Schema([
            SavedCampaign.self,
            CachedArtist.self
        ])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("AudienceAmp: Failed to create ModelContainer — \(error)")
        }
    }()

    // MARK: - App Body
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
#if os(macOS)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1100, height: 720)
#endif
    }
}

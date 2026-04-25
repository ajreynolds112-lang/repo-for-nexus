//
//  AdParameters.swift
//  AudienceAmp
//
//  The final output of the Ad Parameter Engine — ready-to-paste ad targeting data.
//

import Foundation

// MARK: - AdParameters

struct AdParameters: Codable, Identifiable {
    let id: UUID
    let generatedAt: Date
    let sourceArtistIDs: [String]

    // Core outputs
    let locations: [AdLocation]
    let interests: [AdInterest]
    let streamingLikelihoodScore: Double    // 0–100 overall
    let estimatedReach: Int                 // combined monthly listeners
    let recommendedCPMRange: CPMRange

    // Platform-specific formatted strings
    let metaAdsFormat: PlatformAdFormat
    let tiktokAdsFormat: PlatformAdFormat
    let googleAdsFormat: PlatformAdFormat
    let spotifyAdsFormat: PlatformAdFormat
}

// MARK: - Location

struct AdLocation: Codable, Identifiable {
    let id: UUID
    let city: String
    let state: String?
    let country: String
    let neighborhoods: [String]
    let listenerSharePercent: Double
    let streamingLikelihood: Double         // 0–100 per city
    let priorityTier: PriorityTier

    enum PriorityTier: String, Codable {
        case tier1 = "Priority Tier 1"
        case tier2 = "Priority Tier 2"
        case international = "International"
    }
}

// MARK: - Interest

struct AdInterest: Codable, Identifiable {
    let id: UUID
    let name: String
    let category: String
    let affinityScore: Double
    let platforms: [String]                 // which ad platforms support this interest
}

// MARK: - CPM Range

struct CPMRange: Codable {
    let low: Double
    let high: Double
    var formatted: String { String(format: "$%.2f–$%.2f", low, high) }
}

// MARK: - Platform Format

struct PlatformAdFormat: Codable {
    let platform: String
    let locationStrings: [String]           // copy-paste ready
    let interestStrings: [String]
    let audienceSegmentNotes: String
    let exportCSV: String                   // full CSV blob
}

// MARK: - SwiftData Persistent Campaign

import SwiftData

@Model
final class SavedCampaign {
    @Attribute(.unique) var id: UUID
    var name: String
    var createdAt: Date
    var artistNames: [String]
    var genre: String
    var subGenres: [String]
    var adParametersJSON: Data?             // encoded AdParameters

    init(name: String, artistNames: [String], genre: String, subGenres: [String]) {
        self.id          = UUID()
        self.name        = name
        self.createdAt   = Date()
        self.artistNames = artistNames
        self.genre       = genre
        self.subGenres   = subGenres
    }
}

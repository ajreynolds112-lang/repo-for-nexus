//
//  FanProfile.swift
//  AudienceAmp
//
//  Aggregated fan demographics and psychographics for a set of benchmark artists.
//

import Foundation

// MARK: - FanProfile

struct FanProfile: Codable {
    let artistIDs: [String]             // benchmark artists this profile covers
    let generatedAt: Date

    // Demographics
    let ageDistribution: [AgeRange: Double]     // % share per bracket
    let genderDistribution: GenderDistribution
    let topCities: [CityListenerShare]          // ranked by listener density
    let topCountries: [CountryListenerShare]

    // Psychographics
    let coListenedArtists: [String]             // other artists fans stream
    let topInterests: [FanInterest]             // ranked interest tags
    let lifestyleIndicators: [String]           // e.g. "Attends live events"

    // Streaming behaviour
    let avgEngagementRate: Double               // 0.0 – 1.0
    let platformSplit: PlatformSplit
}

// MARK: - Sub-types

enum AgeRange: String, Codable, CaseIterable, Identifiable {
    case teen      = "13–17"
    case youngAdult = "18–24"
    case adult     = "25–34"
    case midAdult  = "35–44"
    case mature    = "45–54"
    case senior    = "55+"
    var id: String { rawValue }
}

struct GenderDistribution: Codable {
    let female: Double      // percentage 0–100
    let male: Double
    let nonBinary: Double
    let unknown: Double
}

struct CityListenerShare: Codable, Identifiable {
    var id: String { city }
    let city: String
    let country: String
    let listenerSharePercent: Double    // % of combined fanbase in this city
    let streamingLikelihood: Double     // 0–100 score
    let neighborhoods: [String]         // known high-density neighborhoods
}

struct CountryListenerShare: Codable, Identifiable {
    var id: String { countryCode }
    let countryCode: String             // ISO 3166-1 alpha-2
    let countryName: String
    let listenerSharePercent: Double
}

struct FanInterest: Codable, Identifiable {
    var id: String { name }
    let name: String
    let category: InterestCategory
    let affinityScore: Double           // 0–100
}

enum InterestCategory: String, Codable, CaseIterable {
    case artist      = "Artist"
    case genre       = "Genre"
    case brand       = "Brand"
    case lifestyle   = "Lifestyle"
    case event       = "Live Events"
    case platform    = "Platform"
    case fashion     = "Fashion"
    case food        = "Food & Beverage"
    case sports      = "Sports"
    case media       = "Media & TV"
}

struct PlatformSplit: Codable {
    let spotifyPercent: Double
    let appleMusicPercent: Double
    let youtubePercent: Double
    let tidalPercent: Double
    let otherPercent: Double
}

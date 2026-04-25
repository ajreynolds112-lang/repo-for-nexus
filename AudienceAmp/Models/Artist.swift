//
//  Artist.swift
//  AudienceAmp
//
//  Core artist model used across all three modules.
//

import Foundation
import SwiftData

// MARK: - Artist (in-memory, Codable)

struct Artist: Identifiable, Codable, Hashable {
    let id: String                      // Spotify or Apple Music artist ID
    let name: String
    let genres: [String]
    let subGenres: [String]
    var monthlyListeners: Int
    let followerCount: Int
    let imageURL: URL?
    let spotifyURL: URL?
    var similarityScore: Double         // 0.0 – 1.0, computed by SimilarityEngine
    var selectionState: SelectionState
    var isRelated: Bool                 // true if surfaced via “related artists” endpoint

    enum SelectionState: String, Codable, Hashable {
        case selected
        case reviewing
        case notSelected
    }

    // Convenience
    var formattedListeners: String {
        let n = monthlyListeners
        switch n {
        case 1_000_000...: return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:     return String(format: "%.1fK", Double(n) / 1_000)
        default:           return "\(n)"
        }
    }

    var matchPercentage: Int { Int(similarityScore * 100) }
}

// MARK: - Spotify Raw Response Models

struct SpotifyArtistSearchResponse: Codable {
    struct Artists: Codable {
        let items: [SpotifyArtistItem]
        let total: Int
        let next: String?
    }
    let artists: Artists
}

struct SpotifyArtistItem: Codable {
    let id: String
    let name: String
    let genres: [String]
    let followers: Followers
    let images: [ArtistImage]
    let externalUrls: ExternalUrls
    let popularity: Int

    struct Followers: Codable  { let total: Int }
    struct ArtistImage: Codable { let url: String; let width: Int; let height: Int }
    struct ExternalUrls: Codable { let spotify: String }

    enum CodingKeys: String, CodingKey {
        case id, name, genres, followers, images, popularity
        case externalUrls = "external_urls"
    }
}

struct SpotifyRelatedArtistsResponse: Codable {
    let artists: [SpotifyArtistItem]
}

// MARK: - SwiftData Persistent Model (cached artist)

@Model
final class CachedArtist {
    @Attribute(.unique) var id: String
    var name: String
    var genres: [String]
    var monthlyListeners: Int
    var followerCount: Int
    var imageURLString: String?
    var similarityScore: Double
    var cachedAt: Date

    init(from artist: Artist) {
        self.id               = artist.id
        self.name             = artist.name
        self.genres           = artist.genres
        self.monthlyListeners = artist.monthlyListeners
        self.followerCount    = artist.followerCount
        self.imageURLString   = artist.imageURL?.absoluteString
        self.similarityScore  = artist.similarityScore
        self.cachedAt         = Date()
    }
}

//
//  SimilarityEngine.swift
//  AudienceAmp
//
//  Pure stateless engine — computes genre similarity score between user and artist.
//  Fully unit-testable, no side effects.
//

import Foundation

enum SimilarityEngine {

    // MARK: - Primary Score (0.0 – 1.0)

    /// Weighted Jaccard similarity across primary genres and sub-genres.
    /// Sub-genre matches are weighted 1.5x vs primary genre matches.
    static func score(
        userGenres: [String],
        userSubGenres: [String],
        artistGenres: [String]
    ) -> Double {
        let userPrimary = Set(userGenres.map { $0.lowercased() })
        let userSub     = Set(userSubGenres.map { $0.lowercased() })
        let artistSet   = Set(artistGenres.map { $0.lowercased() })

        let primaryIntersection = userPrimary.intersection(artistSet).count
        let subIntersection     = userSub.intersection(artistSet).count

        let weightedIntersection = Double(primaryIntersection) + Double(subIntersection) * 1.5
        let union = Double(userPrimary.union(userSub).union(artistSet).count)

        guard union > 0 else { return 0 }
        return min(weightedIntersection / union, 1.0)
    }

    // MARK: - Batch Score

    static func batchScore(
        userGenres: [String],
        userSubGenres: [String],
        artists: [SpotifyArtistItem]
    ) -> [(artist: SpotifyArtistItem, score: Double)] {
        artists.map { artist in
            let s = score(
                userGenres:    userGenres,
                userSubGenres: userSubGenres,
                artistGenres:  artist.genres
            )
            return (artist, s)
        }
        .sorted { $0.score > $1.score }
    }

    // MARK: - Popularity Boost

    /// Blends similarity score with Spotify popularity (0–100) for ranking.
    /// Weight: 70% genre similarity, 30% popularity.
    static func blendedScore(similarityScore: Double, popularity: Int) -> Double {
        let popNorm = Double(popularity) / 100.0
        return (similarityScore * 0.70) + (popNorm * 0.30)
    }
}

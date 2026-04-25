//
//  AppleMusicService.swift
//  AudienceAmp
//
//  Apple Music API client using MusicKit framework.
//

import Foundation
import MusicKit

// MARK: - Protocol

protocol AppleMusicServiceProtocol {
    func searchArtists(query: String, genre: String) async throws -> [Artist]
    func topChartArtists(genre: String, limit: Int) async throws -> [Artist]
}

// MARK: - AppleMusicService

final class AppleMusicService: AppleMusicServiceProtocol {

    // MARK: - Authorization

    func requestAuthorization() async -> MusicAuthorization.Status {
        await MusicAuthorization.request()
    }

    // MARK: - Artist Search

    func searchArtists(query: String, genre: String) async throws -> [Artist] {
        var request = MusicCatalogSearchRequest(term: query, types: [MusicKit.Artist.self])
        request.limit = 20
        let response = try await request.response()
        return response.artists.compactMap { mkArtist in
            Artist(
                id:               "am_\(mkArtist.id.rawValue)",
                name:             mkArtist.name,
                genres:           mkArtist.genreNames,
                subGenres:        [],
                monthlyListeners: 0,
                followerCount:    0,
                imageURL:         mkArtist.artwork?.url(width: 200, height: 200),
                spotifyURL:       nil,
                similarityScore:  SimilarityEngine.score(
                    userGenres:    [genre],
                    userSubGenres: [],
                    artistGenres:  mkArtist.genreNames
                ),
                selectionState:   .notSelected,
                isRelated:        false
            )
        }
    }

    // MARK: - Chart Artists by Genre

    func topChartArtists(genre: String, limit: Int = 20) async throws -> [Artist] {
        var request = MusicCatalogChartsRequest(genre: nil, kinds: [.mostPlayed], types: [MusicKit.Song.self])
        request.limit = limit
        // MusicKit doesn’t expose artist charts directly — derive from top songs
        let response = try await request.response()
        var seen = Set<String>()
        var artists: [Artist] = []
        for song in response.mostPlayedSongs ?? [] {
            guard let artistName = song.artistName, !seen.contains(artistName) else { continue }
            seen.insert(artistName)
            artists.append(Artist(
                id:               "am_chart_\(seen.count)",
                name:             artistName,
                genres:           [genre],
                subGenres:        [],
                monthlyListeners: 0,
                followerCount:    0,
                imageURL:         song.artwork?.url(width: 200, height: 200),
                spotifyURL:       nil,
                similarityScore:  0.70,
                selectionState:   .notSelected,
                isRelated:        false
            ))
        }
        return artists
    }
}

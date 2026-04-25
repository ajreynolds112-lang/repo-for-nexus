//
//  ArtistRepository.swift
//  AudienceAmp
//
//  Abstracts Spotify + Apple Music into a unified Artist model.
//  Handles caching, deduplication, and similarity scoring.
//

import Foundation

// MARK: - Protocol

protocol ArtistRepositoryProtocol {
    func search(query: String, genre: String, subGenres: [String]) async throws -> [Artist]
    func relatedArtists(for artistID: String) async throws -> [Artist]
    func enrichMonthlyListeners(artists: inout [Artist]) async
}

// MARK: - ArtistRepository

final class ArtistRepository: ArtistRepositoryProtocol {

    private let spotifyService: SpotifyServiceProtocol
    private let appleMusicService: AppleMusicServiceProtocol
    private let chartmetricService: ChartmetricServiceProtocol
    private let cache: NSCache<NSString, CachedArtistList>

    init(
        spotifyService:      SpotifyServiceProtocol      = SpotifyService(),
        appleMusicService:   AppleMusicServiceProtocol   = AppleMusicService(),
        chartmetricService:  ChartmetricServiceProtocol  = ChartmetricService()
    ) {
        self.spotifyService     = spotifyService
        self.appleMusicService  = appleMusicService
        self.chartmetricService = chartmetricService
        self.cache              = NSCache()
        self.cache.countLimit   = AppConstants.Cache.artistCacheLimit
    }

    // MARK: - Search

    func search(query: String, genre: String, subGenres: [String]) async throws -> [Artist] {
        let cacheKey = "\(query)-\(genre)-\(subGenres.joined())" as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached.artists }

        // Parallel fetch from Spotify + Apple Music
        async let spotifyResults = fetchFromSpotify(query: query, genre: genre, subGenres: subGenres)
        async let appleMusicResults = fetchFromAppleMusic(query: query, genre: genre)

        let (spotify, apple) = try await (spotifyResults, appleMusicResults)

        // Merge, deduplicate by name (case-insensitive), sort by blended score
        var seen = Set<String>()
        var merged: [Artist] = []
        for artist in (spotify + apple) {
            let key = artist.name.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            merged.append(artist)
        }
        let sorted = merged.sorted { $0.similarityScore > $1.similarityScore }
        cache.setObject(CachedArtistList(artists: sorted), forKey: cacheKey)
        return sorted
    }

    // MARK: - Related Artists

    func relatedArtists(for artistID: String) async throws -> [Artist] {
        // Strip Apple Music prefix if present
        let spotifyID = artistID.hasPrefix("am_") ? nil : artistID
        guard let sid = spotifyID else { return [] }

        let raw = try await spotifyService.relatedArtists(artistID: sid)
        return raw.map { item in
            Artist(
                id:               item.id,
                name:             item.name,
                genres:           item.genres,
                subGenres:        [],
                monthlyListeners: 0,
                followerCount:    item.followers.total,
                imageURL:         URL(string: item.images.first?.url ?? ""),
                spotifyURL:       URL(string: item.externalUrls.spotify),
                similarityScore:  0.75,
                selectionState:   .notSelected,
                isRelated:        true
            )
        }
    }

    // MARK: - Monthly Listener Enrichment

    func enrichMonthlyListeners(artists: inout [Artist]) async {
        await withTaskGroup(of: (String, Int).self) { group in
            for artist in artists {
                group.addTask {
                    let listeners = (try? await self.chartmetricService.monthlyListeners(
                        chartmetricID: artist.id
                    )) ?? 0
                    return (artist.id, listeners)
                }
            }
            var results: [String: Int] = [:]
            for await (id, count) in group { results[id] = count }
            for idx in artists.indices {
                if let count = results[artists[idx].id], count > 0 {
                    artists[idx].monthlyListeners = count
                }
            }
        }
    }

    // MARK: - Private Fetch Helpers

    private func fetchFromSpotify(query: String, genre: String, subGenres: [String]) async throws -> [Artist] {
        let response = try await spotifyService.searchArtists(query: query, genre: genre)
        return response.artists.items.map { item in
            let sim = SimilarityEngine.score(
                userGenres:    [genre],
                userSubGenres: subGenres,
                artistGenres:  item.genres
            )
            let blended = SimilarityEngine.blendedScore(similarityScore: sim, popularity: item.popularity)
            return Artist(
                id:               item.id,
                name:             item.name,
                genres:           item.genres,
                subGenres:        item.genres.filter { subGenres.contains($0) },
                monthlyListeners: 0,
                followerCount:    item.followers.total,
                imageURL:         URL(string: item.images.first?.url ?? ""),
                spotifyURL:       URL(string: item.externalUrls.spotify),
                similarityScore:  blended,
                selectionState:   .notSelected,
                isRelated:        false
            )
        }
    }

    private func fetchFromAppleMusic(query: String, genre: String) async throws -> [Artist] {
        (try? await appleMusicService.searchArtists(query: query, genre: genre)) ?? []
    }
}

// NSCache wrapper
final class CachedArtistList: NSObject {
    let artists: [Artist]
    init(artists: [Artist]) { self.artists = artists }
}

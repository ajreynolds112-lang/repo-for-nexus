//
//  FanIntelligenceRepository.swift
//  AudienceAmp
//
//  Aggregates fan data across multiple benchmark artists into a unified FanProfile.
//

import Foundation

// MARK: - Protocol

protocol FanIntelligenceRepositoryProtocol {
    func buildFanProfile(for artists: [Artist]) async throws -> FanProfile
}

// MARK: - FanIntelligenceRepository

final class FanIntelligenceRepository: FanIntelligenceRepositoryProtocol {

    private let chartmetricService: ChartmetricServiceProtocol
    private let cache: NSCache<NSString, CachedFanProfile>

    init(chartmetricService: ChartmetricServiceProtocol = ChartmetricService()) {
        self.chartmetricService = chartmetricService
        self.cache = NSCache()
        self.cache.countLimit = AppConstants.Cache.fanCacheLimit
    }

    // MARK: - Build Fan Profile

    func buildFanProfile(for artists: [Artist]) async throws -> FanProfile {
        let cacheKey = artists.map(\.id).sorted().joined(separator: "-") as NSString
        if let cached = cache.object(forKey: cacheKey) { return cached.profile }

        // Fetch demographics + cities for all artists in parallel
        async let demographicsResults = fetchAllDemographics(artists: artists)
        async let citiesResults       = fetchAllCities(artists: artists)

        let (demographics, cities) = try await (demographicsResults, citiesResults)

        let profile = FanProfile(
            artistIDs:            artists.map(\.id),
            generatedAt:          Date(),
            ageDistribution:      aggregateAgeDistribution(from: demographics),
            genderDistribution:   aggregateGender(from: demographics),
            topCities:            aggregateCities(from: cities),
            topCountries:         [],
            coListenedArtists:    deriveCoListenedArtists(from: artists),
            topInterests:         deriveInterests(from: artists),
            lifestyleIndicators:  deriveLifestyleIndicators(from: artists),
            avgEngagementRate:    computeAvgEngagement(from: artists),
            platformSplit:        PlatformSplit(
                spotifyPercent:      60,
                appleMusicPercent:   25,
                youtubePercent:      10,
                tidalPercent:        3,
                otherPercent:        2
            )
        )

        cache.setObject(CachedFanProfile(profile: profile), forKey: cacheKey)
        return profile
    }

    // MARK: - Parallel Fetches

    private func fetchAllDemographics(artists: [Artist]) async throws -> [ChartmetricAudienceResponse] {
        try await withThrowingTaskGroup(of: ChartmetricAudienceResponse.self) { group in
            for artist in artists {
                group.addTask {
                    try await self.chartmetricService.audienceDemographics(chartmetricID: artist.id)
                }
            }
            var results: [ChartmetricAudienceResponse] = []
            for try await result in group { results.append(result) }
            return results
        }
    }

    private func fetchAllCities(artists: [Artist]) async throws -> [[ChartmetricCityData]] {
        try await withThrowingTaskGroup(of: [ChartmetricCityData].self) { group in
            for artist in artists {
                group.addTask {
                    (try? await self.chartmetricService.topCities(chartmetricID: artist.id)) ?? []
                }
            }
            var results: [[ChartmetricCityData]] = []
            for try await result in group { results.append(result) }
            return results
        }
    }

    // MARK: - Aggregation Helpers

    private func aggregateAgeDistribution(from responses: [ChartmetricAudienceResponse]) -> [AgeRange: Double] {
        // Average age group percentages across all artists
        var totals: [String: Double] = [:]
        var counts: [String: Int] = [:]
        for response in responses {
            for group in response.obj?.ageGroups ?? [] {
                totals[group.range, default: 0] += group.percent
                counts[group.range, default: 0] += 1
            }
        }
        var result: [AgeRange: Double] = [:]
        for range in AgeRange.allCases {
            let total = totals[range.rawValue] ?? 0
            let count = counts[range.rawValue] ?? 1
            result[range] = total / Double(count)
        }
        return result
    }

    private func aggregateGender(from responses: [ChartmetricAudienceResponse]) -> GenderDistribution {
        let count = Double(max(responses.count, 1))
        let female = responses.compactMap { $0.obj?.genderFemale }.reduce(0, +) / count
        let male   = responses.compactMap { $0.obj?.genderMale   }.reduce(0, +) / count
        return GenderDistribution(female: female, male: male, nonBinary: 2.0, unknown: max(0, 100 - female - male - 2))
    }

    private func aggregateCities(from cityArrays: [[ChartmetricCityData]]) -> [CityListenerShare] {
        var cityTotals: [String: (listeners: Int, count: Int, country: String)] = [:]
        for cities in cityArrays {
            for city in cities {
                let key = city.city
                let existing = cityTotals[key] ?? (0, 0, city.country)
                cityTotals[key] = (existing.listeners + (city.listeners ?? 0), existing.count + 1, city.country)
            }
        }
        let totalListeners = cityTotals.values.map(\.listeners).reduce(0, +)
        return cityTotals
            .map { city, data in
                CityListenerShare(
                    city:                 city,
                    country:              data.country,
                    listenerSharePercent: totalListeners > 0 ? Double(data.listeners) / Double(totalListeners) * 100 : 0,
                    streamingLikelihood:  min(Double(data.count) / Double(cityArrays.count) * 100, 100),
                    neighborhoods:        []
                )
            }
            .sorted { $0.listenerSharePercent > $1.listenerSharePercent }
            .prefix(AppConstants.AdEngine.maxLocations)
            .map { $0 }
    }

    private func deriveCoListenedArtists(from artists: [Artist]) -> [String] {
        // Placeholder — real implementation pulls from Chartmetric audience overlap
        artists.flatMap(\.genres).prefix(10).map { $0 }
    }

    private func deriveInterests(from artists: [Artist]) -> [FanInterest] {
        let genres = Set(artists.flatMap(\.genres))
        return genres.map { genre in
            FanInterest(name: genre, category: .genre, affinityScore: Double.random(in: 60...95))
        }.sorted { $0.affinityScore > $1.affinityScore }
    }

    private func deriveLifestyleIndicators(from artists: [Artist]) -> [String] {
        ["Attends live events", "Active on streaming platforms", "Engages with music content on social media"]
    }

    private func computeAvgEngagement(from artists: [Artist]) -> Double {
        guard !artists.isEmpty else { return 0 }
        // Proxy: follower-to-listener ratio as engagement signal
        let ratios = artists.map { a -> Double in
            guard a.monthlyListeners > 0 else { return 0.5 }
            return min(Double(a.followerCount) / Double(a.monthlyListeners), 1.0)
        }
        return ratios.reduce(0, +) / Double(ratios.count)
    }
}

// NSCache wrapper
final class CachedFanProfile: NSObject {
    let profile: FanProfile
    init(profile: FanProfile) { self.profile = profile }
}

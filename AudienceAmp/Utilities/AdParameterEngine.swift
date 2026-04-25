//
//  AdParameterEngine.swift
//  AudienceAmp
//
//  Stateless computation engine — transforms aggregated fan data and
//  streaming metrics into concrete, ad-manager-ready parameters.
//

import Foundation

enum AdParameterEngine {

    // MARK: - Main Entry Point

    static func generate(
        artists: [Artist],
        fanProfile: FanProfile
    ) -> AdParameters {
        let locations  = buildLocations(from: fanProfile)
        let interests  = buildInterests(from: fanProfile, artists: artists)
        let reach      = artists.reduce(0) { $0 + $1.monthlyListeners }
        let likelihood = computeStreamingLikelihood(artists: artists, fanProfile: fanProfile)
        let cpm        = recommendedCPM(likelihood: likelihood, reach: reach)

        return AdParameters(
            id:                          UUID(),
            generatedAt:                 Date(),
            sourceArtistIDs:             artists.map(\.id),
            locations:                   locations,
            interests:                   interests,
            streamingLikelihoodScore:    likelihood,
            estimatedReach:              reach,
            recommendedCPMRange:         cpm,
            metaAdsFormat:               formatForMeta(locations: locations, interests: interests),
            tiktokAdsFormat:             formatForTikTok(locations: locations, interests: interests),
            googleAdsFormat:             formatForGoogle(locations: locations, interests: interests),
            spotifyAdsFormat:            formatForSpotify(artists: artists, fanProfile: fanProfile)
        )
    }

    // MARK: - Location Builder

    private static func buildLocations(from profile: FanProfile) -> [AdLocation] {
        profile.topCities
            .prefix(AppConstants.AdEngine.maxLocations)
            .enumerated()
            .map { idx, city in
                AdLocation(
                    id:                    UUID(),
                    city:                  city.city,
                    state:                 nil,
                    country:               city.country,
                    neighborhoods:         city.neighborhoods,
                    listenerSharePercent:  city.listenerSharePercent,
                    streamingLikelihood:   city.streamingLikelihood,
                    priorityTier:          idx < 3 ? .tier1 : idx < 8 ? .tier2 : .international
                )
            }
    }

    // MARK: - Interest Builder

    private static func buildInterests(
        from profile: FanProfile,
        artists: [Artist]
    ) -> [AdInterest] {
        var interests: [AdInterest] = []

        // 1. Benchmark artists themselves as interests
        for artist in artists {
            interests.append(AdInterest(
                id:            UUID(),
                name:          artist.name,
                category:      "Artist",
                affinityScore: artist.similarityScore * 100,
                platforms:     ["Meta", "TikTok", "Google", "Spotify"]
            ))
        }

        // 2. Co-listened artists
        for coArtist in profile.coListenedArtists.prefix(10) {
            interests.append(AdInterest(
                id:            UUID(),
                name:          coArtist,
                category:      "Artist",
                affinityScore: 75,
                platforms:     ["Meta", "TikTok", "Google"]
            ))
        }

        // 3. Fan interest tags
        for interest in profile.topInterests.prefix(AppConstants.AdEngine.maxInterests) {
            interests.append(AdInterest(
                id:            UUID(),
                name:          interest.name,
                category:      interest.category.rawValue,
                affinityScore: interest.affinityScore,
                platforms:     platformsFor(category: interest.category)
            ))
        }

        return interests
            .sorted { $0.affinityScore > $1.affinityScore }
            .prefix(AppConstants.AdEngine.maxInterests)
            .map { $0 }
    }

    // MARK: - Streaming Likelihood Score

    /// Formula: (avg engagement × genre affinity × geo density) / market saturation
    /// Output: 0 – 100
    private static func computeStreamingLikelihood(
        artists: [Artist],
        fanProfile: FanProfile
    ) -> Double {
        let avgSimilarity  = artists.isEmpty ? 0 : artists.map(\.similarityScore).reduce(0, +) / Double(artists.count)
        let engagement     = fanProfile.avgEngagementRate          // 0.0 – 1.0
        let geoDensity     = min(Double(fanProfile.topCities.count) / 10.0, 1.0)
        let saturation     = 1.0   // placeholder — wire to market data

        let raw = (engagement * 0.35 + avgSimilarity * 0.45 + geoDensity * 0.20) / saturation
        return min(raw * 100, 100).rounded()
    }

    // MARK: - CPM Recommendation

    private static func recommendedCPM(likelihood: Double, reach: Int) -> CPMRange {
        // Higher likelihood + larger reach = higher CPM floor (more competitive audience)
        let base: Double = likelihood >= 80 ? 7.0 : likelihood >= 60 ? 5.0 : 3.5
        let reachMultiplier = reach > 10_000_000 ? 1.4 : reach > 1_000_000 ? 1.2 : 1.0
        return CPMRange(low: (base * reachMultiplier).rounded(toPlaces: 2),
                        high: (base * reachMultiplier * 1.6).rounded(toPlaces: 2))
    }

    // MARK: - Platform Formatters

    private static func formatForMeta(locations: [AdLocation], interests: [AdInterest]) -> PlatformAdFormat {
        let locationStrings = locations.map { loc in
            var parts = [loc.city]
            if let state = loc.state { parts.append(state) }
            parts.append(loc.country)
            return parts.joined(separator: ", ")
        }
        let interestStrings = interests.filter { $0.platforms.contains("Meta") }.map(\.name)
        let csv = (["Location", "Interest"].joined(separator: ",") + "\n" +
            zip(locationStrings, interestStrings).map { "\($0.0),\($0.1)" }.joined(separator: "\n"))
        return PlatformAdFormat(
            platform:               "Meta Ads",
            locationStrings:        locationStrings,
            interestStrings:        interestStrings,
            audienceSegmentNotes:   "Use Detailed Targeting > Interests. Layer locations with 15–25 mile radius for neighborhoods.",
            exportCSV:              csv
        )
    }

    private static func formatForTikTok(locations: [AdLocation], interests: [AdInterest]) -> PlatformAdFormat {
        let locationStrings = locations.map { "\($0.city), \($0.country)" }
        let interestStrings = interests.filter { $0.platforms.contains("TikTok") }.map(\.name)
        return PlatformAdFormat(
            platform:               "TikTok Ads",
            locationStrings:        locationStrings,
            interestStrings:        interestStrings,
            audienceSegmentNotes:   "Use Interest & Behavior targeting. Add Music > [Genre] category. Creator Lookalike on benchmark artists.",
            exportCSV:              ""
        )
    }

    private static func formatForGoogle(locations: [AdLocation], interests: [AdInterest]) -> PlatformAdFormat {
        let locationStrings = locations.map { "\($0.city), \($0.country)" }
        let interestStrings = interests.filter { $0.platforms.contains("Google") }.map(\.name)
        return PlatformAdFormat(
            platform:               "Google Ads",
            locationStrings:        locationStrings,
            interestStrings:        interestStrings,
            audienceSegmentNotes:   "Use Custom Intent Audiences with artist names as keywords. Layer with In-Market: Music Streaming.",
            exportCSV:              ""
        )
    }

    private static func formatForSpotify(artists: [Artist], fanProfile: FanProfile) -> PlatformAdFormat {
        let genreStrings    = Array(Set(artists.flatMap(\.genres))).sorted()
        let artistStrings   = artists.map(\.name)
        return PlatformAdFormat(
            platform:               "Spotify Ad Studio",
            locationStrings:        fanProfile.topCities.prefix(10).map { $0.city },
            interestStrings:        genreStrings + artistStrings,
            audienceSegmentNotes:   "Target by Genre and Playlist type. Use artist targeting where available in your market.",
            exportCSV:              ""
        )
    }

    // MARK: - Helpers

    private static func platformsFor(category: InterestCategory) -> [String] {
        switch category {
        case .artist:    return ["Meta", "TikTok", "Google", "Spotify"]
        case .genre:     return ["Meta", "Spotify"]
        case .brand:     return ["Meta", "TikTok", "Google"]
        case .lifestyle: return ["Meta", "TikTok"]
        case .event:     return ["Meta", "Google"]
        case .platform:  return ["Meta", "Google"]
        case .fashion:   return ["Meta", "TikTok"]
        case .food:      return ["Meta"]
        case .sports:    return ["Meta", "Google"]
        case .media:     return ["Meta", "TikTok", "Google"]
        }
    }
}

// MARK: - Double Extension

private extension Double {
    func rounded(toPlaces places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}

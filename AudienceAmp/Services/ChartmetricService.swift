//
//  ChartmetricService.swift
//  AudienceAmp
//
//  Chartmetric API client — provides monthly listeners, city-level fan data,
//  audience demographics, and psychographic interest signals.
//

import Foundation

// MARK: - Protocol

protocol ChartmetricServiceProtocol {
    func monthlyListeners(chartmetricID: String) async throws -> Int
    func audienceDemographics(chartmetricID: String) async throws -> ChartmetricAudienceResponse
    func topCities(chartmetricID: String) async throws -> [ChartmetricCityData]
    func spotifyArtistID(name: String) async throws -> String?
}

// MARK: - ChartmetricService

final class ChartmetricService: ChartmetricServiceProtocol {

    private var authToken: String = ""
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.timeoutInterval
        return URLSession(configuration: config)
    }()

    // MARK: - Auth

    func authenticate() async throws {
        let url = URL(string: "\(AppConstants.Chartmetric.baseURL)/token")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["refreshtoken": AppConstants.Chartmetric.apiKey]
        request.httpBody = try JSONEncoder().encode(body)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(ChartmetricTokenResponse.self, from: data)
        authToken = response.token
    }

    // MARK: - Monthly Listeners

    func monthlyListeners(chartmetricID: String) async throws -> Int {
        let url = URL(string: "\(AppConstants.Chartmetric.baseURL)/artist/\(chartmetricID)/stat/spotify")!
        let (data, _) = try await authorizedSession.data(from: url)
        let response = try JSONDecoder().decode(ChartmetricStatResponse.self, from: data)
        return response.obj?.monthlyListeners ?? 0
    }

    // MARK: - Audience Demographics

    func audienceDemographics(chartmetricID: String) async throws -> ChartmetricAudienceResponse {
        let url = URL(string: "\(AppConstants.Chartmetric.baseURL)/artist/\(chartmetricID)/audience")!
        let (data, _) = try await authorizedSession.data(from: url)
        return try JSONDecoder().decode(ChartmetricAudienceResponse.self, from: data)
    }

    // MARK: - Top Cities

    func topCities(chartmetricID: String) async throws -> [ChartmetricCityData] {
        let url = URL(string: "\(AppConstants.Chartmetric.baseURL)/artist/\(chartmetricID)/where-people-listen")!
        let (data, _) = try await authorizedSession.data(from: url)
        let response = try JSONDecoder().decode(ChartmetricCitiesResponse.self, from: data)
        return response.obj?.cities ?? []
    }

    // MARK: - Spotify ID Lookup

    func spotifyArtistID(name: String) async throws -> String? {
        var components = URLComponents(string: "\(AppConstants.Chartmetric.baseURL)/search")!
        components.queryItems = [
            .init(name: "q",    value: name),
            .init(name: "type", value: "artists"),
            .init(name: "limit",value: "1")
        ]
        let (data, _) = try await authorizedSession.data(from: components.url!)
        let response = try JSONDecoder().decode(ChartmetricSearchResponse.self, from: data)
        return response.obj?.artists?.first?.spotifyID
    }

    // MARK: - Helpers

    private var authorizedSession: URLSession {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Authorization": "Bearer \(authToken)"]
        config.timeoutIntervalForRequest = AppConstants.Network.timeoutInterval
        return URLSession(configuration: config)
    }
}

// MARK: - Chartmetric Response Models

struct ChartmetricTokenResponse: Codable {
    let token: String
}

struct ChartmetricStatResponse: Codable {
    struct Obj: Codable {
        let monthlyListeners: Int?
        enum CodingKeys: String, CodingKey {
            case monthlyListeners = "monthly_listeners"
        }
    }
    let obj: Obj?
}

struct ChartmetricAudienceResponse: Codable {
    struct Obj: Codable {
        let genderMale: Double?
        let genderFemale: Double?
        let ageGroups: [AgeGroup]?
        enum CodingKeys: String, CodingKey {
            case genderMale   = "gender_male"
            case genderFemale = "gender_female"
            case ageGroups    = "age_groups"
        }
    }
    struct AgeGroup: Codable {
        let range: String
        let percent: Double
    }
    let obj: Obj?
}

struct ChartmetricCitiesResponse: Codable {
    struct Obj: Codable {
        let cities: [ChartmetricCityData]?
    }
    let obj: Obj?
}

struct ChartmetricCityData: Codable, Identifiable {
    var id: String { city }
    let city: String
    let country: String
    let rank: Int
    let listeners: Int?
}

struct ChartmetricSearchResponse: Codable {
    struct Obj: Codable {
        let artists: [ChartmetricArtistResult]?
    }
    struct ChartmetricArtistResult: Codable {
        let spotifyID: String?
        enum CodingKeys: String, CodingKey {
            case spotifyID = "spotify_id"
        }
    }
    let obj: Obj?
}

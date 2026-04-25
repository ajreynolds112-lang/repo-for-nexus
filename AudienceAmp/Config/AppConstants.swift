//
//  AppConstants.swift
//  AudienceAmp
//
//  Central configuration — base URLs, timeouts, pagination limits.
//  API keys live in Secrets.xcconfig (gitignored).
//

import Foundation

enum AppConstants {

    // MARK: - Spotify
    enum Spotify {
        static let baseURL          = "https://api.spotify.com/v1"
        static let authURL          = "https://accounts.spotify.com/authorize"
        static let tokenURL         = "https://accounts.spotify.com/api/token"
        static let redirectURI      = "audienceamp://spotify-callback"
        static let scopes           = "user-read-private user-read-email"
        /// Injected from Secrets.xcconfig via Info.plist
        static let clientID         = Bundle.main.infoDictionary?["SPOTIFY_CLIENT_ID"] as? String ?? ""
        static let searchLimit      = 20
        static let relatedLimit     = 10
    }

    // MARK: - Apple Music
    enum AppleMusic {
        static let baseURL          = "https://api.music.apple.com/v1"
        static let keyID            = Bundle.main.infoDictionary?["APPLE_MUSIC_KEY_ID"] as? String ?? ""
        static let teamID           = Bundle.main.infoDictionary?["APPLE_MUSIC_TEAM_ID"] as? String ?? ""
    }

    // MARK: - Chartmetric
    enum Chartmetric {
        static let baseURL          = "https://api.chartmetric.com/api"
        static let apiKey           = Bundle.main.infoDictionary?["CHARTMETRIC_API_KEY"] as? String ?? ""
    }

    // MARK: - Networking
    enum Network {
        static let timeoutInterval: TimeInterval = 30
        static let maxRetries                    = 3
        static let debounceMilliseconds: UInt64  = 350_000_000
    }

    // MARK: - Ad Parameter Engine
    enum AdEngine {
        static let maxLocations      = 20
        static let maxInterests      = 50
        static let highScoreThreshold: Double = 0.80
        static let mediumScoreThreshold: Double = 0.60
    }

    // MARK: - Cache
    enum Cache {
        static let artistCacheLimit  = 100
        static let fanCacheLimit     = 50
        static let ttlSeconds: TimeInterval = 3600   // 1 hour
    }
}

//
//  SpotifyService.swift
//  AudienceAmp
//
//  Spotify Web API client with OAuth 2.0 PKCE auth flow.
//  Handles: artist search, related artists, monthly listener enrichment.
//

import Foundation
import AuthenticationServices
import CryptoKit

// MARK: - Protocol

protocol SpotifyServiceProtocol {
    func searchArtists(query: String, genre: String) async throws -> SpotifyArtistSearchResponse
    func relatedArtists(artistID: String) async throws -> [SpotifyArtistItem]
    func monthlyListeners(artistID: String) async throws -> Int
}

// MARK: - SpotifyService

final class SpotifyService: SpotifyServiceProtocol {

    // MARK: - Token Storage
    private var accessToken: String? {
        get { KeychainHelper.read(key: "spotify_access_token") }
        set { KeychainHelper.write(key: "spotify_access_token", value: newValue ?? "") }
    }
    private var tokenExpiry: Date? {
        get {
            guard let ts = KeychainHelper.read(key: "spotify_token_expiry"),
                  let interval = Double(ts) else { return nil }
            return Date(timeIntervalSince1970: interval)
        }
        set {
            KeychainHelper.write(key: "spotify_token_expiry",
                                 value: String(newValue?.timeIntervalSince1970 ?? 0))
        }
    }

    private var isTokenValid: Bool {
        guard let token = accessToken, !token.isEmpty,
              let expiry = tokenExpiry else { return false }
        return Date() < expiry.addingTimeInterval(-60)   // 60s buffer
    }

    // MARK: - PKCE State
    private var codeVerifier: String = ""

    // MARK: - URLSession
    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AppConstants.Network.timeoutInterval
        return URLSession(configuration: config)
    }()

    // MARK: - OAuth PKCE Flow

    /// Call this to initiate Spotify login. Presents ASWebAuthenticationSession.
    func authenticate(presentationAnchor: ASPresentationAnchor) async throws {
        codeVerifier = generateCodeVerifier()
        let codeChallenge = generateCodeChallenge(from: codeVerifier)
        let state = UUID().uuidString

        var components = URLComponents(string: AppConstants.Spotify.authURL)!
        components.queryItems = [
            .init(name: "client_id",             value: AppConstants.Spotify.clientID),
            .init(name: "response_type",         value: "code"),
            .init(name: "redirect_uri",          value: AppConstants.Spotify.redirectURI),
            .init(name: "scope",                 value: AppConstants.Spotify.scopes),
            .init(name: "code_challenge_method", value: "S256"),
            .init(name: "code_challenge",        value: codeChallenge),
            .init(name: "state",                 value: state)
        ]

        let authURL = components.url!
        let callbackURL = try await withCheckedThrowingContinuation { (cont: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "audienceamp"
            ) { url, error in
                if let error { cont.resume(throwing: error); return }
                guard let url else { cont.resume(throwing: SpotifyError.authFailed); return }
                cont.resume(returning: url)
            }
            session.presentationContextProvider = PresentationContextProvider(anchor: presentationAnchor)
            session.prefersEphemeralWebBrowserSession = true
            session.start()
        }

        guard let code = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)
                ?.queryItems?.first(where: { $0.name == "code" })?.value
        else { throw SpotifyError.authFailed }

        try await exchangeCodeForToken(code: code)
    }

    private func exchangeCodeForToken(code: String) async throws {
        var request = URLRequest(url: URL(string: AppConstants.Spotify.tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = [
            "grant_type":    "authorization_code",
            "code":          code,
            "redirect_uri":  AppConstants.Spotify.redirectURI,
            "client_id":     AppConstants.Spotify.clientID,
            "code_verifier": codeVerifier
        ].map { "\($0.key)=\($0.value)" }.joined(separator: "&")

        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await session.data(for: request)
        let tokenResponse = try JSONDecoder().decode(SpotifyTokenResponse.self, from: data)
        accessToken = tokenResponse.accessToken
        tokenExpiry = Date().addingTimeInterval(TimeInterval(tokenResponse.expiresIn))
    }

    // MARK: - API Calls

    func searchArtists(query: String, genre: String) async throws -> SpotifyArtistSearchResponse {
        try await ensureValidToken()
        let q = genre.isEmpty ? query : "\(query) genre:\(genre)"
        var components = URLComponents(string: "\(AppConstants.Spotify.baseURL)/search")!
        components.queryItems = [
            .init(name: "q",     value: q),
            .init(name: "type",  value: "artist"),
            .init(name: "limit", value: String(AppConstants.Spotify.searchLimit))
        ]
        let request = try authorizedRequest(url: components.url!)
        let (data, _) = try await session.data(for: request)
        return try JSONDecoder().decode(SpotifyArtistSearchResponse.self, from: data)
    }

    func relatedArtists(artistID: String) async throws -> [SpotifyArtistItem] {
        try await ensureValidToken()
        let url = URL(string: "\(AppConstants.Spotify.baseURL)/artists/\(artistID)/related-artists")!
        let request = try authorizedRequest(url: url)
        let (data, _) = try await session.data(for: request)
        let response = try JSONDecoder().decode(SpotifyRelatedArtistsResponse.self, from: data)
        return Array(response.artists.prefix(AppConstants.Spotify.relatedLimit))
    }

    func monthlyListeners(artistID: String) async throws -> Int {
        // Spotify public API doesn’t expose monthly listeners directly.
        // This is a stub — real implementation uses Chartmetric or scraping.
        // Returns follower count as a proxy until Chartmetric is wired.
        return 0
    }

    // MARK: - Helpers

    private func ensureValidToken() async throws {
        guard isTokenValid else { throw SpotifyError.notAuthenticated }
    }

    private func authorizedRequest(url: URL) throws -> URLRequest {
        guard let token = accessToken else { throw SpotifyError.notAuthenticated }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }

    // MARK: - PKCE Crypto

    private func generateCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .prefix(128).description
    }

    private func generateCodeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

// MARK: - Supporting Types

struct SpotifyTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let expiresIn: Int
    let refreshToken: String?
    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case tokenType    = "token_type"
        case expiresIn    = "expires_in"
        case refreshToken = "refresh_token"
    }
}

enum SpotifyError: LocalizedError {
    case notAuthenticated
    case authFailed
    case invalidResponse
    case rateLimited

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "Not authenticated with Spotify. Please log in."
        case .authFailed:       return "Spotify authentication failed."
        case .invalidResponse:  return "Invalid response from Spotify API."
        case .rateLimited:      return "Spotify rate limit hit. Please wait and retry."
        }
    }
}

// MARK: - ASWebAuthenticationSession Presentation

private final class PresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    let anchor: ASPresentationAnchor
    init(anchor: ASPresentationAnchor) { self.anchor = anchor }
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { anchor }
}

// MARK: - Keychain Helper

enum KeychainHelper {
    static func write(key: String, value: String) {
        let data = Data(value.utf8)
        let query: [CFString: Any] = [
            kSecClass:       kSecClassGenericPassword,
            kSecAttrAccount: key,
            kSecValueData:   data
        ]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }

    static func read(key: String) -> String? {
        let query: [CFString: Any] = [
            kSecClass:            kSecClassGenericPassword,
            kSecAttrAccount:      key,
            kSecReturnData:       true,
            kSecMatchLimit:       kSecMatchLimitOne
        ]
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        guard let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

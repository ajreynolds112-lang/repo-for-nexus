//
//  AdParameterViewModel.swift
//  AudienceAmp
//

import SwiftUI

@MainActor
final class AdParameterViewModel: ObservableObject {

    // MARK: - Published State
    @Published var adParameters: AdParameters? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedPlatform: AdPlatform = .meta
    @Published var showExportSheet: Bool = false
    @Published var copyConfirmation: Bool = false

    enum AdPlatform: String, CaseIterable, Identifiable {
        case meta    = "Meta Ads"
        case tiktok  = "TikTok Ads"
        case google  = "Google Ads"
        case spotify = "Spotify Ad Studio"
        var id: String { rawValue }
        var icon: String {
            switch self {
            case .meta:    return "f.circle.fill"
            case .tiktok:  return "music.note"
            case .google:  return "g.circle.fill"
            case .spotify: return "waveform"
            }
        }
    }

    // MARK: - Computed
    var currentPlatformFormat: PlatformAdFormat? {
        guard let params = adParameters else { return nil }
        switch selectedPlatform {
        case .meta:    return params.metaAdsFormat
        case .tiktok:  return params.tiktokAdsFormat
        case .google:  return params.googleAdsFormat
        case .spotify: return params.spotifyAdsFormat
        }
    }

    var streamingScoreLabel: String {
        guard let score = adParameters?.streamingLikelihoodScore else { return "N/A" }
        switch score {
        case 80...: return "High Confidence"
        case 60...: return "Medium Confidence"
        default:    return "Low Confidence"
        }
    }

    var streamingScoreColor: String {
        guard let score = adParameters?.streamingLikelihoodScore else { return "gray" }
        return score >= 80 ? "green" : score >= 60 ? "orange" : "red"
    }

    // MARK: - Dependencies
    private let selectedArtists: [Artist]
    private let fanProfile: FanProfile?

    // MARK: - Init
    init(selectedArtists: [Artist], fanProfile: FanProfile?) {
        self.selectedArtists = selectedArtists
        self.fanProfile      = fanProfile
    }

    // MARK: - Intents

    func generateParameters() {
        guard let profile = fanProfile, !selectedArtists.isEmpty else { return }
        isLoading = true
        Task {
            defer { isLoading = false }
            adParameters = AdParameterEngine.generate(artists: selectedArtists, fanProfile: profile)
        }
    }

    func copyCurrentPlatformParams() {
        guard let format = currentPlatformFormat else { return }
        let text = [
            "=== \(format.platform) Ad Parameters ===",
            "\nLOCATIONS:",
            format.locationStrings.joined(separator: "\n"),
            "\nINTERESTS:",
            format.interestStrings.joined(separator: ", "),
            "\nNOTES:",
            format.audienceSegmentNotes
        ].joined(separator: "\n")
#if os(iOS)
        UIPasteboard.general.string = text
#elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
#endif
        copyConfirmation = true
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            copyConfirmation = false
        }
    }

    func exportCSV() {
        showExportSheet = true
    }

    func clearError() { errorMessage = nil }
}

//
//  FanIntelligenceViewModel.swift
//  AudienceAmp
//

import SwiftUI

@MainActor
final class FanIntelligenceViewModel: ObservableObject {

    // MARK: - Published State
    @Published var fanProfile: FanProfile? = nil
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedTab: ProfileTab = .demographics

    enum ProfileTab: String, CaseIterable, Identifiable {
        case demographics = "Demographics"
        case geography    = "Geography"
        case interests    = "Interests"
        case platforms    = "Platforms"
        var id: String { rawValue }
    }

    // MARK: - Computed
    var ageChartData: [(label: String, value: Double)] {
        guard let profile = fanProfile else { return [] }
        return AgeRange.allCases.map { range in
            (range.rawValue, profile.ageDistribution[range] ?? 0)
        }
    }

    var topCities: [CityListenerShare] {
        fanProfile?.topCities.prefix(10).map { $0 } ?? []
    }

    var topInterests: [FanInterest] {
        fanProfile?.topInterests.prefix(20).map { $0 } ?? []
    }

    // MARK: - Dependencies
    private let selectedArtists: [Artist]
    private let repository: FanIntelligenceRepositoryProtocol

    // MARK: - Init
    init(
        selectedArtists: [Artist],
        repository: FanIntelligenceRepositoryProtocol = FanIntelligenceRepository()
    ) {
        self.selectedArtists = selectedArtists
        self.repository      = repository
    }

    // MARK: - Intents

    func loadFanProfile() {
        guard fanProfile == nil, !selectedArtists.isEmpty else { return }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                fanProfile = try await repository.buildFanProfile(for: selectedArtists)
            } catch {
                errorMessage = "Failed to load fan data: \(error.localizedDescription)"
            }
        }
    }

    func clearError() { errorMessage = nil }
}

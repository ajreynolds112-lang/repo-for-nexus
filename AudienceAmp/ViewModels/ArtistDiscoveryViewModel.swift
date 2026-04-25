//
//  ArtistDiscoveryViewModel.swift
//  AudienceAmp
//

import SwiftUI
import Combine

@MainActor
final class ArtistDiscoveryViewModel: ObservableObject {

    // MARK: - Published State
    @Published var searchQuery: String = ""
    @Published var artists: [Artist] = []
    @Published var selectedArtists: [Artist] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var sortOption: SortOption = .similarityScore
    @Published var showRelatedBadge: String? = nil  // artist ID that just had related loaded

    // MARK: - Computed
    var sortedArtists: [Artist] {
        switch sortOption {
        case .similarityScore:   return artists.sorted { $0.similarityScore > $1.similarityScore }
        case .monthlyListeners:  return artists.sorted { $0.monthlyListeners > $1.monthlyListeners }
        case .followerCount:     return artists.sorted { $0.followerCount > $1.followerCount }
        case .name:              return artists.sorted { $0.name < $1.name }
        }
    }
    var hasSelections: Bool { !selectedArtists.isEmpty }
    var selectionCount: Int { selectedArtists.count }

    // MARK: - Dependencies
    private let repository: ArtistRepositoryProtocol
    private let userGenre: String
    private let userSubGenres: [String]
    private var searchTask: Task<Void, Never>?

    enum SortOption: String, CaseIterable, Identifiable {
        case similarityScore  = "Similarity"
        case monthlyListeners = "Monthly Listeners"
        case followerCount    = "Followers"
        case name             = "Name"
        var id: String { rawValue }
    }

    // MARK: - Init
    init(
        genre: String,
        subGenres: [String],
        repository: ArtistRepositoryProtocol = ArtistRepository()
    ) {
        self.userGenre    = genre
        self.userSubGenres = subGenres
        self.repository   = repository
    }

    // MARK: - Intents

    func onSearchQueryChanged(_ query: String) {
        searchTask?.cancel()
        guard query.count >= 2 else { artists = []; return }
        searchTask = Task {
            try? await Task.sleep(nanoseconds: AppConstants.Network.debounceMilliseconds)
            guard !Task.isCancelled else { return }
            await performSearch(query: query)
        }
    }

    func toggleSelection(artist: Artist) {
        guard let idx = artists.firstIndex(where: { $0.id == artist.id }) else { return }
        switch artists[idx].selectionState {
        case .notSelected: artists[idx].selectionState = .reviewing
        case .reviewing:   artists[idx].selectionState = .selected
        case .selected:    artists[idx].selectionState = .notSelected
        }
        selectedArtists = artists.filter { $0.selectionState == .selected }
    }

    func loadRelatedArtists(for artist: Artist) {
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                let related = try await repository.relatedArtists(for: artist.id)
                let existingIDs = Set(artists.map(\.id))
                let newOnes = related.filter { !existingIDs.contains($0.id) }
                artists.append(contentsOf: newOnes)
                showRelatedBadge = artist.id
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                showRelatedBadge = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    func clearError() { errorMessage = nil }

    // MARK: - Private
    private func performSearch(query: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            var results = try await repository.search(
                query: query,
                genre: userGenre,
                subGenres: userSubGenres
            )
            await repository.enrichMonthlyListeners(artists: &results)
            artists = results
        } catch {
            errorMessage = "Search failed: \(error.localizedDescription)"
        }
    }
}

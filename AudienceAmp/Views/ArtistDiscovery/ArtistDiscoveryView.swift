//
//  ArtistDiscoveryView.swift
//  AudienceAmp
//

import SwiftUI

struct ArtistDiscoveryView: View {

    @StateObject private var vm: ArtistDiscoveryViewModel
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var navigationPath = NavigationPath()
    @State private var showSortSheet = false

    init(genre: String, subGenres: [String]) {
        _vm = StateObject(wrappedValue: ArtistDiscoveryViewModel(genre: genre, subGenres: subGenres))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if sizeClass == .regular {
                    HStack(spacing: 0) {
                        artistListPanel.frame(minWidth: 340, maxWidth: 420)
                        Divider()
                        selectionSidebar
                    }
                } else {
                    artistListPanel
                }
            }
            .navigationTitle("Artist Discovery")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSortSheet = true } label: {
                        Label("Sort", systemImage: "arrow.up.arrow.down")
                    }
                }
            }
            .navigationDestination(for: [Artist].self) { artists in
                FanIntelligenceView(selectedArtists: artists)
            }
            .sheet(isPresented: $showSortSheet) { sortSheet }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.clearError() }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }

    // MARK: - Artist List Panel
    private var artistListPanel: some View {
        VStack(spacing: 0) {
            searchBar
            sortChipStrip
            if vm.isLoading { loadingView }
            else if vm.artists.isEmpty && !vm.searchQuery.isEmpty { emptyStateView }
            else { artistList }
            proceedButton
        }
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField("Search artists, genres...", text: $vm.searchQuery)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .onChange(of: vm.searchQuery) { _, new in vm.onSearchQueryChanged(new) }
            if !vm.searchQuery.isEmpty {
                Button { vm.searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
            }
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .padding(.top, 8)
    }

    private var sortChipStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ArtistDiscoveryViewModel.SortOption.allCases) { option in
                    FilterChip(label: option.rawValue, isSelected: vm.sortOption == option) {
                        vm.sortOption = option
                    }
                }
            }
            .padding(.horizontal).padding(.vertical, 8)
        }
    }

    private var artistList: some View {
        List(vm.sortedArtists) { artist in
            ArtistRowView(artist: artist,
                onToggle:  { vm.toggleSelection(artist: artist) },
                onRelated: { vm.loadRelatedArtists(for: artist) }
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: vm.sortedArtists.map(\.id))
    }

    private var selectionSidebar: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Selected (\(vm.selectionCount))")
                .font(.headline).padding(.horizontal).padding(.top)
            if vm.selectedArtists.isEmpty {
                ContentUnavailableView("No Artists Selected",
                    systemImage: "person.badge.plus",
                    description: Text("Tap artists to add them"))
            } else {
                List(vm.selectedArtists) { artist in
                    HStack {
                        AsyncImage(url: artist.imageURL) { img in img.resizable().scaledToFill() }
                            placeholder: { Color.secondary.opacity(0.3) }
                            .frame(width: 36, height: 36).clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artist.name).font(.subheadline.weight(.semibold))
                            Text(artist.genres.prefix(2).joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button { vm.toggleSelection(artist: artist) } label: {
                            Image(systemName: "xmark").foregroundStyle(.secondary)
                        }.buttonStyle(.plain)
                    }
                }.listStyle(.plain)
            }
            Spacer()
            proceedButton.padding()
        }
        .frame(maxWidth: .infinity)
    }

    private var proceedButton: some View {
        Button {
            navigationPath.append(vm.selectedArtists)
        } label: {
            Label("Analyze \(vm.selectionCount) Artist\(vm.selectionCount == 1 ? "" : "s")",
                  systemImage: "arrow.right.circle.fill")
                .frame(maxWidth: .infinity).padding()
                .background(vm.hasSelections ? Color.accentColor : Color.secondary.opacity(0.3))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(!vm.hasSelections)
        .padding([.horizontal, .bottom])
        .animation(.easeInOut, value: vm.hasSelections)
    }

    private var loadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("Searching artists...").font(.subheadline).foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        ContentUnavailableView.search(text: vm.searchQuery)
    }

    private var sortSheet: some View {
        NavigationStack {
            List(ArtistDiscoveryViewModel.SortOption.allCases) { option in
                Button {
                    vm.sortOption = option; showSortSheet = false
                } label: {
                    HStack {
                        Text(option.rawValue)
                        Spacer()
                        if vm.sortOption == option {
                            Image(systemName: "checkmark").foregroundStyle(.accentColor)
                        }
                    }
                }.foregroundStyle(.primary)
            }
            .navigationTitle("Sort By").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showSortSheet = false }
                }
            }
        }.presentationDetents([.medium])
    }
}

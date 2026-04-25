//
//  FanIntelligenceView.swift
//  AudienceAmp
//

import SwiftUI
import Charts

struct FanIntelligenceView: View {

    @StateObject private var vm: FanIntelligenceViewModel
    @State private var navigationPath = NavigationPath()
    private let selectedArtists: [Artist]

    init(selectedArtists: [Artist]) {
        self.selectedArtists = selectedArtists
        _vm = StateObject(wrappedValue: FanIntelligenceViewModel(selectedArtists: selectedArtists))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if vm.isLoading {
                    loadingView
                } else if let profile = vm.fanProfile {
                    profileContent(profile: profile)
                } else {
                    emptyState
                }
            }
            .navigationTitle("Fan Intelligence")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(for: FanProfile.self) { profile in
                AdParameterView(selectedArtists: selectedArtists, fanProfile: profile)
            }
            .onAppear { vm.loadFanProfile() }
            .alert("Error", isPresented: .constant(vm.errorMessage != nil)) {
                Button("OK") { vm.clearError() }
            } message: { Text(vm.errorMessage ?? "") }
        }
    }

    // MARK: - Profile Content

    private func profileContent(profile: FanProfile) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Artist summary chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(selectedArtists) { artist in
                            FilterChip(label: artist.name, isSelected: true) {}
                        }
                    }.padding(.horizontal)
                }

                // Tab selector
                Picker("Tab", selection: $vm.selectedTab) {
                    ForEach(FanIntelligenceViewModel.ProfileTab.allCases) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                switch vm.selectedTab {
                case .demographics: demographicsSection(profile: profile)
                case .geography:    geographySection(profile: profile)
                case .interests:    interestsSection(profile: profile)
                case .platforms:    platformsSection(profile: profile)
                }

                // Proceed button
                Button {
                    navigationPath.append(profile)
                } label: {
                    Label("Generate Ad Parameters", systemImage: "target")
                        .frame(maxWidth: .infinity).padding()
                        .background(Color.accentColor)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }

    // MARK: - Demographics
    private func demographicsSection(profile: FanProfile) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Age Distribution").font(.headline).padding(.horizontal)
            Chart {
                ForEach(vm.ageChartData, id: \.label) { item in
                    BarMark(x: .value("Age", item.label), y: .value("%", item.value))
                        .foregroundStyle(Color.accentColor.gradient)
                }
            }
            .frame(height: 200)
            .padding(.horizontal)

            Text("Gender Split").font(.headline).padding(.horizontal)
            HStack(spacing: 0) {
                genderBar(label: "Female", value: profile.genderDistribution.female, color: .pink)
                genderBar(label: "Male",   value: profile.genderDistribution.male,   color: .blue)
                genderBar(label: "Other",  value: profile.genderDistribution.nonBinary, color: .purple)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .frame(height: 40)
            .padding(.horizontal)
        }
    }

    private func genderBar(label: String, value: Double, color: Color) -> some View {
        GeometryReader { geo in
            color.frame(width: geo.size.width * (value / 100))
                .overlay(Text("\(Int(value))%").font(.caption2.bold()).foregroundStyle(.white))
        }
    }

    // MARK: - Geography
    private func geographySection(profile: FanProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Listener Cities").font(.headline).padding(.horizontal)
            ForEach(vm.topCities) { city in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(city.city).font(.subheadline.weight(.semibold))
                        Text(city.country).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(String(format: "%.1f%%", city.listenerSharePercent))
                            .font(.subheadline.weight(.semibold))
                        Text(String(format: "Score: %.0f", city.streamingLikelihood))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                Divider().padding(.leading)
            }
        }
    }

    // MARK: - Interests
    private func interestsSection(profile: FanProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Fan Interests").font(.headline).padding(.horizontal)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 10) {
                ForEach(vm.topInterests) { interest in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(interest.name).font(.caption.weight(.semibold)).lineLimit(1)
                            Text(interest.category.rawValue).font(.caption2).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(String(format: "%.0f", interest.affinityScore))
                            .font(.caption2.bold()).foregroundStyle(.accentColor)
                    }
                    .padding(8)
                    .background(Color.secondary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Platforms
    private func platformsSection(profile: FanProfile) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Platform Distribution").font(.headline).padding(.horizontal)
            let split = profile.platformSplit
            let data: [(String, Double)] = [
                ("Spotify", split.spotifyPercent),
                ("Apple Music", split.appleMusicPercent),
                ("YouTube", split.youtubePercent),
                ("Tidal", split.tidalPercent),
                ("Other", split.otherPercent)
            ]
            Chart {
                ForEach(data, id: \.0) { item in
                    SectorMark(angle: .value("%", item.1), innerRadius: .ratio(0.5))
                        .foregroundStyle(by: .value("Platform", item.0))
                }
            }
            .frame(height: 220)
            .padding(.horizontal)
        }
    }

    // MARK: - Loading / Empty
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text("Aggregating fan data...").foregroundStyle(.secondary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyState: some View {
        ContentUnavailableView("No Artists Selected",
            systemImage: "person.3",
            description: Text("Go back and select benchmark artists first."))
    }
}

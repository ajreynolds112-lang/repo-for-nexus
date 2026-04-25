//
//  OnboardingView.swift
//  AudienceAmp
//

import SwiftUI

struct OnboardingView: View {

    @State private var artistName: String = ""
    @State private var primaryGenre: String = ""
    @State private var selectedSubGenres: Set<String> = []
    @State private var currentStep: Int = 0
    @AppStorage("onboardingComplete") private var onboardingComplete: Bool = false

    var availableSubGenres: [String] {
        GenreTaxonomy.subGenres(for: primaryGenre)
    }

    var canProceed: Bool {
        switch currentStep {
        case 0: return artistName.count >= 2
        case 1: return !primaryGenre.isEmpty
        case 2: return true   // sub-genre optional
        default: return true
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress
            ProgressView(value: Double(currentStep + 1), total: 4)
                .tint(.accentColor)
                .padding(.horizontal)
                .padding(.top)

            TabView(selection: $currentStep) {
                stepArtistName.tag(0)
                stepGenre.tag(1)
                stepSubGenre.tag(2)
                stepConnect.tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: currentStep)

            // Navigation
            HStack {
                if currentStep > 0 {
                    Button("Back") { currentStep -= 1 }
                        .buttonStyle(.bordered)
                }
                Spacer()
                Button(currentStep < 3 ? "Continue" : "Get Started") {
                    if currentStep < 3 { currentStep += 1 }
                    else { onboardingComplete = true }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canProceed)
            }
            .padding()
        }
        .navigationTitle("Setup")
    }

    // MARK: - Steps

    private var stepArtistName: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("What\'s your artist name?")
                .font(.largeTitle.bold())
            Text("We\'ll use this to personalize your audience research.")
                .foregroundStyle(.secondary)
            TextField("e.g. Aria Nova", text: $artistName)
                .textFieldStyle(.roundedBorder)
                .font(.title3)
            Spacer()
        }
        .padding()
    }

    private var stepGenre: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Primary Genre")
                .font(.largeTitle.bold())
            Text("Pick the genre that best describes your sound.")
                .foregroundStyle(.secondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 120))], spacing: 12) {
                ForEach(GenreTaxonomy.primaryGenres, id: \.self) { genre in
                    FilterChip(label: genre, isSelected: primaryGenre == genre) {
                        primaryGenre = genre
                        selectedSubGenres = []
                    }
                }
            }
            Spacer()
        }
        .padding()
    }

    private var stepSubGenre: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Sub-Genre(s)")
                .font(.largeTitle.bold())
            Text("Select all that apply. This improves matching accuracy.")
                .foregroundStyle(.secondary)
            if availableSubGenres.isEmpty {
                Text("No sub-genres available for \(primaryGenre).")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 12) {
                    ForEach(availableSubGenres, id: \.self) { sub in
                        FilterChip(label: sub, isSelected: selectedSubGenres.contains(sub)) {
                            if selectedSubGenres.contains(sub) { selectedSubGenres.remove(sub) }
                            else { selectedSubGenres.insert(sub) }
                        }
                    }
                }
            }
            Spacer()
        }
        .padding()
    }

    private var stepConnect: some View {
        VStack(spacing: 24) {
            Image(systemName: "music.note.house.fill")
                .font(.system(size: 64))
                .foregroundStyle(.accentColor)
            Text("Connect Your Streaming Profile")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("Optionally connect Spotify for Artists or Apple Music for Artists to cross-reference your own listener data.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            VStack(spacing: 12) {
                Button("Connect Spotify for Artists") { /* OAuth flow */ }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                Button("Connect Apple Music for Artists") { /* OAuth flow */ }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
            }
            Button("Skip for now") { onboardingComplete = true }
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding()
    }
}

//
//  AdParameterView.swift
//  AudienceAmp
//

import SwiftUI

struct AdParameterView: View {

    @StateObject private var vm: AdParameterViewModel

    init(selectedArtists: [Artist], fanProfile: FanProfile?) {
        _vm = StateObject(wrappedValue: AdParameterViewModel(
            selectedArtists: selectedArtists, fanProfile: fanProfile))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if vm.isLoading {
                    ProgressView("Generating parameters...").padding(.top, 60)
                } else if let params = vm.adParameters {
                    parametersContent(params: params)
                } else {
                    generatePrompt
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Ad Parameters")
        .navigationBarTitleDisplayMode(.large)
        .onAppear { vm.generateParameters() }
    }

    // MARK: - Generate Prompt
    private var generatePrompt: some View {
        VStack(spacing: 16) {
            Image(systemName: "target").font(.system(size: 56)).foregroundStyle(.accentColor)
            Text("Ready to generate your ad parameters")
                .font(.headline).multilineTextAlignment(.center)
            Button("Generate Parameters") { vm.generateParameters() }
                .buttonStyle(.borderedProminent)
        }.padding(.top, 60)
    }

    // MARK: - Parameters Content
    private func parametersContent(params: AdParameters) -> some View {
        VStack(spacing: 20) {

            // KPI row
            HStack(spacing: 12) {
                kpiCard(title: "Reach", value: formatReach(params.estimatedReach), icon: "radio")
                kpiCard(title: "Score", value: String(format: "%.0f/100", params.streamingLikelihoodScore), icon: "chart.line.uptrend.xyaxis")
                kpiCard(title: "CPM", value: params.recommendedCPMRange.formatted, icon: "dollarsign.circle")
            }.padding(.horizontal)

            // Platform picker
            Picker("Platform", selection: $vm.selectedPlatform) {
                ForEach(AdParameterViewModel.AdPlatform.allCases) { p in
                    Text(p.rawValue).tag(p)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)

            // Platform format
            if let format = vm.currentPlatformFormat {
                platformSection(format: format)
            }

            // Locations
            locationSection(locations: params.locations)

            // Export buttons
            HStack(spacing: 12) {
                Button {
                    vm.copyCurrentPlatformParams()
                } label: {
                    Label(vm.copyConfirmation ? "Copied!" : "Copy Parameters",
                          systemImage: vm.copyConfirmation ? "checkmark" : "doc.on.clipboard")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(vm.copyConfirmation ? .green : .accentColor)

                Button { vm.exportCSV() } label: {
                    Label("Export CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Sub-Views
    private func kpiCard(title: String, value: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(.accentColor)
            Text(value).font(.subheadline.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(Color.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func platformSection(format: PlatformAdFormat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Interests for \(format.platform)").font(.headline).padding(.horizontal)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 130))], spacing: 8) {
                ForEach(format.interestStrings.prefix(24), id: \.self) { interest in
                    Text(interest)
                        .font(.caption)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .foregroundStyle(.accentColor)
                        .clipShape(Capsule())
                }
            }.padding(.horizontal)

            Text(format.audienceSegmentNotes)
                .font(.caption).foregroundStyle(.secondary)
                .padding(.horizontal)
        }
    }

    private func locationSection(locations: [AdLocation]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Target Locations").font(.headline).padding(.horizontal)
            ForEach(locations.prefix(10)) { loc in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text(loc.city).font(.subheadline.weight(.semibold))
                            Text(loc.priorityTier.rawValue)
                                .font(.caption2.weight(.medium))
                                .padding(.horizontal, 5).padding(.vertical, 2)
                                .background(tierColor(loc.priorityTier).opacity(0.15))
                                .foregroundStyle(tierColor(loc.priorityTier))
                                .clipShape(Capsule())
                        }
                        if !loc.neighborhoods.isEmpty {
                            Text(loc.neighborhoods.prefix(3).joined(separator: " · "))
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text(String(format: "%.1f%%", loc.listenerSharePercent))
                            .font(.subheadline.bold())
                        Text(String(format: "Score %.0f", loc.streamingLikelihood))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                Divider().padding(.leading)
            }
        }
    }

    private func tierColor(_ tier: AdLocation.PriorityTier) -> Color {
        switch tier {
        case .tier1:        return .green
        case .tier2:        return .orange
        case .international: return .blue
        }
    }

    private func formatReach(_ n: Int) -> String {
        switch n {
        case 1_000_000_000...: return String(format: "%.1fB", Double(n) / 1_000_000_000)
        case 1_000_000...:     return String(format: "%.1fM", Double(n) / 1_000_000)
        case 1_000...:         return String(format: "%.1fK", Double(n) / 1_000)
        default:               return "\(n)"
        }
    }
}

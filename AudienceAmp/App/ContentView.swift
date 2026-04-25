//
//  ContentView.swift
//  AudienceAmp
//
//  Root navigation shell — adapts between iPhone (tab bar) and Mac/iPad (sidebar)
//

import SwiftUI

struct ContentView: View {

    @State private var selectedTab: AppTab = .discover
    @Environment(\.horizontalSizeClass) private var sizeClass

    enum AppTab: String, CaseIterable, Identifiable {
        case discover  = "Discover"
        case fans      = "Fan Intel"
        case adParams  = "Ad Params"
        case campaigns = "Campaigns"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .discover:  return "magnifyingglass.circle.fill"
            case .fans:      return "person.3.fill"
            case .adParams:  return "target"
            case .campaigns: return "folder.fill"
            }
        }
    }

    var body: some View {
        Group {
#if os(macOS)
            macLayout
#else
            if sizeClass == .regular {
                macLayout   // iPad gets sidebar too
            } else {
                iPhoneLayout
            }
#endif
        }
    }

    // MARK: - iPhone Tab Bar
    private var iPhoneLayout: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                tabDestination(tab)
                    .tabItem {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                    .tag(tab)
            }
        }
    }

    // MARK: - Mac / iPad Sidebar
    private var macLayout: some View {
        NavigationSplitView {
            List(AppTab.allCases, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
                    .tag(tab)
            }
            .navigationTitle("AudienceAmp")
            .listStyle(.sidebar)
        } detail: {
            tabDestination(selectedTab)
        }
    }

    // MARK: - Destination Router
    @ViewBuilder
    private func tabDestination(_ tab: AppTab) -> some View {
        switch tab {
        case .discover:  ArtistDiscoveryView(genre: "", subGenres: [])
        case .fans:      FanIntelligenceView(selectedArtists: [])
        case .adParams:  AdParameterView(selectedArtists: [], fanProfile: nil)
        case .campaigns: CampaignsView()
        }
    }
}

#Preview {
    ContentView()
}
